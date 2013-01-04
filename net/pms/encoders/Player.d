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
module net.pms.encoders.Player;

import java.io.File;
import java.lang.exceptions;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.StringTokenizer;

//import javax.swing.JComponent;

import net.pms.configuration.PmsConfiguration;
import net.pms.configuration.RendererConfiguration;
import net.pms.dlna.DLNAMediaAudio;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.dlna.DLNAMediaSubtitle;
import net.pms.dlna.DLNAResource;
import net.pms.external.ExternalFactory;
import net.pms.external.ExternalListener;
import net.pms.external.FinalizeTranscoderArgsListener;
import net.pms.formats.Format;
import net.pms.io.OutputParams;
import net.pms.io.ProcessWrapper;
import net.pms.util.FileUtil;
import net.pms.util.Iso639;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class Player {
	private static immutable Logger logger = LoggerFactory.getLogger!Player();

	public static const int VIDEO_SIMPLEFILE_PLAYER = 0;
	public static const int AUDIO_SIMPLEFILE_PLAYER = 1;
	public static const int VIDEO_WEBSTREAM_PLAYER = 2;
	public static const int AUDIO_WEBSTREAM_PLAYER = 3;
	public static const int MISC_PLAYER = 4;
	public static const String NATIVE = "NATIVE";

	public abstract int purpose();
	public abstract JComponent config();
	public abstract String id();
	public abstract String name();

	public abstract int type();

	// FIXME this is an implementation detail (and not a very good one).
	// it's entirely up to engines how they construct their command lines.
	// need to get rid of this
	deprecated
	public abstract String[] args();

	public abstract String mimeType();
	public abstract String executable();
	private static List/*<FinalizeTranscoderArgsListener>*/ finalizeTranscoderArgsListeners =
		new ArrayList/*<FinalizeTranscoderArgsListener>*/();

	public static void initializeFinalizeTranscoderArgsListeners() {
		foreach (ExternalListener listener ; ExternalFactory.getExternalListeners()) {
			if (cast(FinalizeTranscoderArgsListener)listener !is null) {
				finalizeTranscoderArgsListeners.add(cast(FinalizeTranscoderArgsListener) listener);
			}
		}
	}

	public bool avisynth() {
		return false;
	}

	public bool excludeFormat(Format extension) {
		return false;
	}

	public bool isPlayerCompatible(RendererConfiguration renderer) {
		return true;
	}

	public bool isInternalSubtitlesSupported() {
		return true;
	}

	public bool isExternalSubtitlesSupported() {
		return true;
	}

	public bool isTimeSeekable() {
		return false;
	}

	public abstract ProcessWrapper launchTranscode(
		String filename,
		DLNAResource dlna,
		DLNAMediaInfo media,
		OutputParams params
	);

	override
	public String toString() {
		return name();
	}

	// no need to pass Player as a parameter: it's the invocant
	deprecated
	protected String[] finalizeTranscoderArgs(
		Player player,
		String filename,
		DLNAResource dlna,
		DLNAMediaInfo media,
		OutputParams params,
		String[] cmdArgs
	) {
		return finalizeTranscoderArgs(
			filename,
			dlna,
			media,
			params,
			cmdArgs
		);
	}

	protected String[] finalizeTranscoderArgs(
		String filename,
		DLNAResource dlna,
		DLNAMediaInfo media,
		OutputParams params,
		String[] cmdArgs
	) {
		if (finalizeTranscoderArgsListeners.isEmpty()) {
			return cmdArgs;
		} else {
			// make it mutable
			List/*<String>*/ cmdList = new ArrayList/*<String>*/(Arrays.asList(cmdArgs));

			foreach (FinalizeTranscoderArgsListener listener ; finalizeTranscoderArgsListeners) {
				try {
					cmdList = listener.finalizeTranscoderArgs(
						this,
						filename,
						dlna,
						media,
						params,
						cmdList
					);
				} catch (Throwable t) {
					logger.error(String.format("Failed to call finalizeTranscoderArgs on listener of type=%s", listener.getClass()), t);
				}
			}

			String[] cmdArray = new String[ cmdList.size() ];
			cmdList.toArray(cmdArray);
			return cmdArray;
		}
	}

	/**
	 * This method populates the supplied {@link OutputParams} object with the correct audio track (aid)
	 * and subtitles (sid), based on the given filename, its MediaInfo metadata and PMS configuration settings.
	 * 
	 * @param fileName
	 *            The file name used to determine the availability of subtitles.
	 * @param media
	 *            The MediaInfo metadata for the file.
	 * @param params
	 *            The parameters to populate.
	 * @param configuration
	 *            The PMS configuration settings.
	 */
	// FIXME this code is almost unreadable in its current form and should be broken down into separate methods
	// that handle just one facet of its functionality. it also needs to be decoupled from MEncoder
	public void setAudioAndSubs(String fileName, DLNAMediaInfo media, OutputParams params, PmsConfiguration configuration) {
		if (params.aid is null && media !is null) {
			// check for preferred audio
			StringTokenizer st = new StringTokenizer(configuration.getMencoderAudioLanguages(), ",");

			while (st !is null && st.hasMoreTokens()) {
				String lang = st.nextToken();
				lang = lang.trim();
				logger.trace("Looking for an audio track with lang: " ~ lang);

				foreach (DLNAMediaAudio audio ; media.getAudioTracksList()) {
					if (audio.matchCode(lang)) {
						params.aid = audio;
						logger.trace("Matched audio track: " ~ audio);
						st = null;
						break;
					}
				}
			}
		}

		if (params.aid is null && media.getAudioTracksList().size() > 0) {
			// take a default audio track, dts first if possible
			foreach (DLNAMediaAudio audio ; media.getAudioTracksList()) {
				if (audio.isDTS()) {
					params.aid = audio;
					logger.trace("Found priority audio track with DTS: " ~ audio);
					break;
				}
			}

			if (params.aid is null) {
				params.aid = media.getAudioTracksList().get(0);
				logger.trace("Chose a default audio track: " ~ params.aid);
			}
		}

		String currentLang = null;
		DLNAMediaSubtitle matchedSub = null;

		if (params.aid !is null) {
			currentLang = params.aid.getLang();
		}

		if (params.sid !is null && params.sid.getId() == -1) {
			logger.trace("Don't want subtitles!");
			params.sid = null;
			return;
		}

		StringTokenizer st1 = new StringTokenizer(configuration.getMencoderAudioSubLanguages(), ";");

		while (st1.hasMoreTokens()) {
			String pair = st1.nextToken();
			if (pair.contains(",")) {
				String audio = pair.substring(0, pair.indexOf(","));
				String sub = pair.substring(pair.indexOf(",") + 1);
				audio = audio.trim();
				sub = sub.trim();
				logger.trace("Searching for a match for: " ~ currentLang ~ " with " ~ audio ~ " and " ~ sub);

				if (Iso639.isCodesMatching(audio, currentLang) || (currentLang !is null && audio.opEquals("*"))) {
					if (sub.opEquals("off")) {
						matchedSub = new DLNAMediaSubtitle();
						matchedSub.setLang("off");
					} else {
						foreach (DLNAMediaSubtitle present_sub ; media.getSubtitleTracksList()) {
							if (present_sub.matchCode(sub) || sub.opEquals("*")) {
								matchedSub = present_sub;
								logger.trace("Found a match: " ~ matchedSub);
								break;
							}
						}
					}

					if (matchedSub !is null) {
						break;
					}
				}
			}
		}

		if (matchedSub !is null && params.sid is null) {
			if (configuration.isMencoderDisableSubs() || (matchedSub.getLang() !is null && matchedSub.getLang().opEquals("off"))) {
				logger.trace(" Disabled the subtitles: " ~ matchedSub);
			} else {
				params.sid = matchedSub;
			}
		}

		if (!configuration.isMencoderDisableSubs() && params.sid is null && media !is null) {
			// Check for subtitles again
			File video = new File(fileName);
			FileUtil.doesSubtitlesExists(video, media, false);

			if (configuration.isAutoloadSubtitles()) {
				bool forcedSubsFound = false;
				// Priority to external subtitles
				foreach (DLNAMediaSubtitle sub ; media.getSubtitleTracksList()) {
					if (matchedSub !is null && matchedSub.getLang() !is null && matchedSub.getLang().opEquals("off")) {
						StringTokenizer st = new StringTokenizer(configuration.getMencoderForcedSubTags(), ",");

						while (st !is null && sub.getFlavor() !is null && st.hasMoreTokens()) {
							String forcedTags = st.nextToken();
							forcedTags = forcedTags.trim();

							if (sub.getFlavor().toLowerCase().indexOf(forcedTags) > -1
									&& Iso639.isCodesMatching(sub.getLang(), configuration.getMencoderForcedSubLanguage())) {

								logger.trace("Forcing preferred subtitles : " ~ sub.getLang() ~ "/" ~ sub.getFlavor());
								logger.trace("Forced subtitles track : " ~ sub);

								if (sub.getExternalFile() !is null) {
									logger.trace("Found external forced file : " ~ sub.getExternalFile().getAbsolutePath());
								}
								params.sid = sub;
								forcedSubsFound = true;
								break;
							}
						}
						if (forcedSubsFound == true) {
							break;
						}
					} else {
						logger.trace("Found subtitles track: " ~ sub);

						if (sub.getExternalFile() !is null) {
							logger.trace("Found external file: " ~ sub.getExternalFile().getAbsolutePath());
							params.sid = sub;
							break;
						}
					}
				}
			}

			if (
				matchedSub !is null && 
				matchedSub.getLang() !is null && 
				matchedSub.getLang().opEquals("off")
			) {
				return;
			}

			if (params.sid is null) {
				StringTokenizer st = new StringTokenizer(configuration.getMencoderSubLanguages(), ",");

				while (st !is null && st.hasMoreTokens()) {
					String lang = st.nextToken();
					lang = lang.trim();
					logger.trace("Looking for a subtitle track with lang: " ~ lang);

					foreach (DLNAMediaSubtitle sub ; media.getSubtitleTracksList()) {
						if (sub.matchCode(lang)) {
							params.sid = sub;
							logger.trace("Matched sub track: " ~ params.sid);
							st = null;
							break;
						}
					}
				}
			}
		}
	}

	/**
	 * Returns whether or not the player can handle a given resource.
	 * If the resource is <code>null</code> compatibility cannot be
	 * determined and <code>false</code> will be returned.
	 * 
	 * @param resource
	 *            The {@link DLNAResource} to be matched.
	 * @return True when the resource can be handled, false otherwise.
	 * @since 1.60.0
	 */
	public abstract bool isCompatible(DLNAResource resource);
}
