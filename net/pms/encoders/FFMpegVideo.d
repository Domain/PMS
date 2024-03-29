/*
 * PS3 Media Server, for streaming any medias to your PS3.
 * Copyright (C) 2008  A.Brochard
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; version 2
 * of the License only.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
module net.pms.encoders.FFMpegVideo;


//import java.awt.event.KeyEvent;
//import java.awt.event.KeyListener;
//import java.awt.Font;
import java.lang.exceptions;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

//import javax.swing.JComponent;
//import javax.swing.JTextField;

import net.pms.configuration.RendererConfiguration;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.dlna.DLNAMediaSubtitle;
import net.pms.dlna.DLNAResource;
import net.pms.formats.Format;
import net.pms.io.OutputParams;
import net.pms.io.ProcessWrapper;
import net.pms.io.ProcessWrapperImpl;
import net.pms.Messages;
import net.pms.network.HTTPResource;
import net.pms.PMS;

import org.apache.commons.lang.StringUtils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

//import com.jgoodies.forms.builder.PanelBuilder;
//import com.jgoodies.forms.factories.Borders;
//import com.jgoodies.forms.layout.CellConstraints;
//import com.jgoodies.forms.layout.FormLayout;

/**
 * Pure FFmpeg video player.
 *
 * Design note:
 *
 * Helper methods that return lists of <code>String</code>s representing options are public
 * to facilitate composition e.g. a custom engine (plugin) that uses tsMuxeR for videos without
 * subtitles and FFmpeg otherwise needs to compose and call methods on both players.
 *
 * To avoid API churn, and to provide wiggle room for future functionality, all of these methods
 * take RendererConfiguration (renderer) and DLNAMediaInfo (media) parameters, even if one or
 * both of these parameters are unused.
 */
public class FFMpegVideo : Player {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!FFMpegVideo();
	private JTextField ffmpeg;
	private static const String DEFAULT_QSCALE = "3";

	// FIXME we have an id() accessor for this; no need for the field to be public
	deprecated
	public static const String ID = "ffmpegvideo";

	/**
	 * Returns a list of strings representing the rescale options for this transcode i.e. the ffmpeg -vf
	 * options used to resize a video that's too wide and/or high for the specified renderer.
	 * If the renderer has no size limits, or there's no media metadata, or the video is within the renderer's
	 * size limits, an empty list is returned.
	 *
	 * @param renderer the DLNA renderer the video is being streamed to
	 * @param media metadata for the DLNA resource which is being transcoded
	 * @return a {@link List} of <code>String</code>s representing the rescale options for this video,
	 * or an empty list if the video doesn't need to be resized.
	 */
	public List/*<String>*/ getRescaleOptions(RendererConfiguration renderer, DLNAMediaInfo media) {
		List/*<String>*/ rescaleOptions = new ArrayList/*<String>*/();

		bool isResolutionTooHighForRenderer = renderer.isVideoRescale() // renderer defines a max width/height
			&& (media !is null)
			&& (
					(media.getWidth() > renderer.getMaxVideoWidth())
					||
					(media.getHeight() > renderer.getMaxVideoHeight())
			   );

		if (isResolutionTooHighForRenderer) {
			String rescaleSpec = String.format(
				// http://stackoverflow.com/a/8351875
				"scale=iw*min(%1$d/iw\\,%2$d/ih):ih*min(%1$d/iw\\,%2$d/ih),pad=%1$d:%2$d:(%1$d-iw)/2:(%2$d-ih)/2",
				renderer.getMaxVideoWidth(),
				renderer.getMaxVideoHeight()
			);

			rescaleOptions.add("-vf");
			rescaleOptions.add(rescaleSpec);
		}

		return rescaleOptions;
	}

	/**
	 * Takes a renderer and returns a list of <code>String</code>s representing ffmpeg output options
	 * (i.e. options that define the output file's video codec, audio codec and container)
	 * compatible with the renderer's <code>TranscodeVideo</code> profile.
	 *
	 * @param renderer The {@link RendererConfiguration} instance whose <code>TranscodeVideo</code> profile is to be processed.
	 * @param media the media metadata for the video being streamed. May contain unset/null values (e.g. for web videos).
	 * @return a {@link List} of <code>String</code>s representing the ffmpeg output parameters for the renderer according
	 * to its <code>TranscodeVideo</code> profile.
	 */
	public List/*<String>*/ getTranscodeVideoOptions(RendererConfiguration renderer, DLNAMediaInfo media) {
		List/*<String>*/ transcodeOptions = new ArrayList/*<String>*/();

		if (renderer.isTranscodeToWMV()) { // WMV
			transcodeOptions.add("-c:v");
			transcodeOptions.add("wmv2");

			transcodeOptions.add("-c:a");
			transcodeOptions.add("wma2");

			transcodeOptions.add("-f");
			transcodeOptions.add("asf");
		} else { // MPEGPSAC3 or MPEGTSAC3
			transcodeOptions.add("-c:v");
			transcodeOptions.add("mpeg2video");

			transcodeOptions.add("-c:a");
			transcodeOptions.add("ac3");

			if (renderer.isTranscodeToMPEGTSAC3()) { // MPEGTSAC3
				transcodeOptions.add("-f");
				transcodeOptions.add("mpegts");
			} else { // default: MPEGPSAC3
				transcodeOptions.add("-f");
				transcodeOptions.add("vob");
			}
		}

		return transcodeOptions;
	}

	/**
	 * Takes a renderer and metadata for the current video and returns the video bitrate spec for the current transcode according to
	 * the limits/requirements of the renderer.
	 *
	 * @param renderer a {@link RendererConfiguration} instance representing the renderer being streamed to
	 * @param media the media metadata for the video being streamed. May contain unset/null values (e.g. for web videos).
	 * @return a {@link List} of <code>String</code>s representing the video bitrate options for this transcode
	 */
	public List/*<String>*/ getVideoBitrateOptions(RendererConfiguration renderer, DLNAMediaInfo media) { // media is currently unused
		List/*<String>*/ videoBitrateOptions = new ArrayList/*<String>*/();
		String sMaxVideoBitrate = renderer.getMaxVideoBitrate(); // currently Mbit/s
		int iMaxVideoBitrate = 0;

		if (sMaxVideoBitrate !is null) {
			try {
				iMaxVideoBitrate = Integer.parseInt(sMaxVideoBitrate);
			} catch (NumberFormatException nfe) {
				LOGGER.error("Can't parse max video bitrate", nfe); // XXX this should be handled in RendererConfiguration
			}
		}

		if (iMaxVideoBitrate == 0) { // unlimited: try to preserve the bitrate
			videoBitrateOptions.add("-q:v"); // video qscale
			videoBitrateOptions.add(DEFAULT_QSCALE);
		} else { // limit the bitrate FIXME untested
			// convert megabits-per-second (as per the current option name: MaxVideoBitrateMbps) to bps
			// FIXME rather than dealing with megabit vs mebibit issues here, this should be left up to the client i.e.
			// the renderer.conf unit should be bits-per-second (and the option should be renamed: MaxVideoBitrateMbps -> MaxVideoBitrate)
			videoBitrateOptions.add("-b:v");
			videoBitrateOptions.add("" + iMaxVideoBitrate * 1000 * 1000);
		}

		return videoBitrateOptions;
	}

	/**
	 * Takes a renderer and metadata for the current video and returns the audio bitrate spec for the current transcode according to
	 * the limits/requirements of the renderer.
	 *
	 * @param renderer a {@link RendererConfiguration} instance representing the renderer being streamed to
	 * @param media the media metadata for the video being streamed. May contain unset/null values (e.g. for web videos).
	 * @return a {@link List} of <code>String</code>s representing the audio bitrate options for this transcode
	 */
	public List/*<String>*/ getAudioBitrateOptions(RendererConfiguration renderer, DLNAMediaInfo media) {
		List/*<String>*/ audioBitrateOptions = new ArrayList/*<String>*/();

		audioBitrateOptions.add("-q:a");
		audioBitrateOptions.add(DEFAULT_QSCALE);

		return audioBitrateOptions;
	}

	override
	public int purpose() {
		return VIDEO_SIMPLEFILE_PLAYER;
	}

	override
	// TODO make this static so it can replace ID, instead of having both
	public String id() {
		return ID;
	}

	override
	public bool isTimeSeekable() {
		return true;
	}

	override
	deprecated
	public bool avisynth() {
		return false;
	}

	override
	public String name() {
		return "FFmpeg";
	}

	override
	public int type() {
		return Format.VIDEO;
	}

	// unused; return this array for backwards-compatibility
	deprecated
	protected String[] getDefaultArgs() {
		return [
			"-vcodec",
			"mpeg2video",
			"-f",
			"vob",
			"-acodec",
			"ac3"
		];
	}

	override
	deprecated
	public String[] args() {
		return getDefaultArgs(); // unused; return this array for for backwards compatibility
	}

	private List/*<String>*/ getCustomArgs() {
		List/*<String>*/ customOptions = new ArrayList/*<String>*/();
		String customOptionsString = PMS.getConfiguration().getFfmpegSettings();

		if (StringUtils.isNotBlank(customOptionsString)) {
			LOGGER._debug("Custom ffmpeg output options: %s", customOptionsString);
		}

		Collections.addAll(customOptions, StringUtils.split(customOptionsString));
		return customOptions;
	}

	// XXX hardwired to false and not referenced anywhere else in the codebase
	deprecated
	public bool mplayer() {
		return false;
	}

	override
	public String mimeType() {
		return HTTPResource.VIDEO_TRANSCODE;
	}

	override
	public String executable() {
		return PMS.getConfiguration().getFfmpegPath();
	}

	override
	public ProcessWrapper launchTranscode(
		String fileName,
		DLNAResource dlna,
		DLNAMediaInfo media,
		OutputParams params
	) {
		return getFFMpegTranscode(fileName, dlna, media, params, null);
	}

	// XXX pointless redirection of launchTranscode
	// TODO remove this method and move its body into launchTranscode
	// TODO call setAudioAndSubs to populate params with audio track/subtitles metadata
	deprecated
	protected ProcessWrapperImpl getFFMpegTranscode(
		String fileName,
		DLNAResource dlna,
		DLNAMediaInfo media,
		OutputParams params,
		String args[]
	) {
		int nThreads = PMS.getConfiguration().getNumberOfCpuCores();
		List/*<String>*/ cmdList = new ArrayList/*<String>*/();
		RendererConfiguration renderer = params.mediaRenderer;

		cmdList.add(executable());

		cmdList.add("-loglevel");
		cmdList.add("warning");

		if (params.timeseek > 0) {
			cmdList.add("-ss");
			cmdList.add("" + params.timeseek);
		}

		// decoder threads
		cmdList.add("-threads");
		cmdList.add("" + nThreads);

		cmdList.add("-i");
		cmdList.add(fileName);

		// encoder threads
		cmdList.add("-threads");
		cmdList.add("" + nThreads);

		if (params.timeend > 0) {
			cmdList.add("-t");
			cmdList.add("" + params.timeend);
		}

		// add video bitrate options
		cmdList.addAll(getVideoBitrateOptions(renderer, media));

		// add audio bitrate options
		cmdList.addAll(getAudioBitrateOptions(renderer, media));

		// if the source is too large for the renderer, resize it
		cmdList.addAll(getRescaleOptions(renderer, media));

		// add custom args
		cmdList.addAll(getCustomArgs());

		// add the output options (-f, -acodec, -vcodec)
		cmdList.addAll(getTranscodeVideoOptions(renderer, media));

		cmdList.add("pipe:");

		String[] cmdArray = new String[ cmdList.size() ];
		cmdList.toArray(cmdArray);

		cmdArray = finalizeTranscoderArgs(
			fileName,
			dlna,
			media,
			params,
			cmdArray
		);

		ProcessWrapperImpl pw = new ProcessWrapperImpl(cmdArray, params);
		pw.runInNewThread();

		return pw;
	}

	override
	public JComponent config() {
		return config("FFMpegVideo.1");
	}

	protected JComponent config(String languageLabel) {
		FormLayout layout = new FormLayout(
			"left:pref, 0:grow",
			"p, 3dlu, p, 3dlu"
		);
		PanelBuilder builder = new PanelBuilder(layout);
		builder.setBorder(Borders.EMPTY_BORDER);
		builder.setOpaque(false);

		CellConstraints cc = new CellConstraints();

		JComponent cmp = builder.addSeparator(Messages.getString(languageLabel), cc.xyw(2, 1, 1));
		cmp = cast(JComponent) cmp.getComponent(0);
		cmp.setFont(cmp.getFont().deriveFont(Font.BOLD));

		ffmpeg = new JTextField(PMS.getConfiguration().getFfmpegSettings());
		ffmpeg.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				PMS.getConfiguration().setFfmpegSettings(ffmpeg.getText());
			}
		});

		builder.add(ffmpeg, cc.xy(2, 3));

		return builder.getPanel();
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public bool isCompatible(DLNAResource resource) {
		if (resource is null || resource.getFormat().getType() != Format.VIDEO) {
			return false;
		}

		DLNAMediaSubtitle subtitle = resource.getMediaSubtitle();

		// Check whether the subtitle actually has a language defined,
		// uninitialized DLNAMediaSubtitle objects have a null language.
		if (subtitle !is null && subtitle.getLang() !is null) {
			// The resource needs a subtitle, but PMS support for FFmpeg subtitles has not yet been implemented.
			return false;
		}

		try {
			String audioTrackName = resource.getMediaAudio().toString();
			String defaultAudioTrackName = resource.getMedia().getAudioTracksList().get(0).toString();

			if (!audioTrackName.opEquals(defaultAudioTrackName)) {
				// PMS only supports playback of the default audio track for FFmpeg
				return false;
			}
		} catch (NullPointerException e) {
			LOGGER.trace("FFmpeg cannot determine compatibility based on audio track for "
					~ resource.getSystemName());
		} catch (IndexOutOfBoundsException e) {
			LOGGER.trace("FFmpeg cannot determine compatibility based on default audio track for "
					~ resource.getSystemName());
		}

		Format format = resource.getFormat();

		if (format !is null) {
			Format.Identifier id = format.getIdentifier();

			if (id.opEquals(Format.Identifier.MKV) || id.opEquals(Format.Identifier.MPG)) {
				return true;
			}
		}

		return false;
	}
}
