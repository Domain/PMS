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
module net.pms.encoders.MPlayerAudio;

import com.jgoodies.forms.builder.PanelBuilder;
import com.jgoodies.forms.factories.Borders;
import com.jgoodies.forms.layout.CellConstraints;
import com.jgoodies.forms.layout.FormLayout;
import net.pms.Messages;
import net.pms.PMS;
import net.pms.configuration.PmsConfiguration;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.dlna.DLNAResource;
import net.pms.formats.Format;
import net.pms.io.OutputParams;
import net.pms.io.PipeProcess;
import net.pms.io.ProcessWrapper;
import net.pms.io.ProcessWrapperImpl;
import net.pms.network.HTTPResource;

//import javax.swing.*;
//import java.awt.*;
import java.awt.event.ItemEvent;
import java.awt.event.ItemListener;
import java.lang.exceptions;
import java.util.Arrays;

// this does nothing that isn't done by the ffmpeg audio engine
// and, indeed, it delegates to ffmpeg for MP3 transcodes
deprecated
public class MPlayerAudio : Player {
	public static const String ID = "mplayeraudio";
	private immutable PmsConfiguration configuration;

	// XXX should be private
	deprecated
	JCheckBox noresample;

	public this(PmsConfiguration configuration) {
		this.configuration = configuration;
	}

	override
	public String id() {
		return ID;
	}

	override
	public int purpose() {
		return AUDIO_SIMPLEFILE_PLAYER;
	}

	override
	public String[] args() {
		return [];
	}

	override
	public String executable() {
		return PMS.getConfiguration().getMplayerPath();
	}

	override
	public ProcessWrapper launchTranscode(
		String fileName,
		DLNAResource dlna,
		DLNAMediaInfo media,
		OutputParams params
	) {
		if (!(cast(MPlayerWebAudio)this !is null) && !(cast(MPlayerWebVideoDump)this !is null)) {
			params.waitbeforestart = 2000;
		}

		params.manageFastStart();

		if (params.mediaRenderer.isTranscodeToMP3()) {
			FFMpegAudio ffmpegAudio = new FFMpegAudio(configuration);
			return ffmpegAudio.launchTranscode(fileName, dlna, media, params);
		}

		params.maxBufferSize = PMS.getConfiguration().getMaxAudioBuffer();
		PipeProcess audioP = new PipeProcess("mplayer_aud" ~ System.currentTimeMillis().toString());

		String mPlayerdefaultAudioArgs[] = [
			PMS.getConfiguration().getMplayerPath(),
			fileName,
			"-prefer-ipv4",
			"-nocache",
			"-af",
			"channels=2",
			"-srate",
			"48000",
			"-vo",
			"null",
			"-ao",
			"pcm:nowaveheader:fast:file=" ~ audioP.getInputPipe(),
			"-quiet",
			"-format",
			"s16be"
		];

		if (params.mediaRenderer.isTranscodeToWAV()) {
			mPlayerdefaultAudioArgs[11] = "pcm:waveheader:fast:file=" ~ audioP.getInputPipe();
			mPlayerdefaultAudioArgs[13] = "-quiet";
			mPlayerdefaultAudioArgs[14] = "-quiet";
		}

		if (params.mediaRenderer.isTranscodeAudioTo441()) {
			mPlayerdefaultAudioArgs[7] = "44100";
		}

		if (!configuration.isAudioResample()) {
			mPlayerdefaultAudioArgs[6] = "-quiet";
			mPlayerdefaultAudioArgs[7] = "-quiet";
		}

		params.input_pipes[0] = audioP;

		if (params.timeseek > 0 || params.timeend > 0) {
			mPlayerdefaultAudioArgs = Arrays.copyOf(mPlayerdefaultAudioArgs, mPlayerdefaultAudioArgs.length + 4);
			mPlayerdefaultAudioArgs[mPlayerdefaultAudioArgs.length - 4] = "-ss";
			mPlayerdefaultAudioArgs[mPlayerdefaultAudioArgs.length - 3] = "" ~ params.timeseek;

			if (params.timeend > 0) {
				mPlayerdefaultAudioArgs[mPlayerdefaultAudioArgs.length - 2] = "-endpos";
				mPlayerdefaultAudioArgs[mPlayerdefaultAudioArgs.length - 1] = "" ~ params.timeend;
			} else {
				mPlayerdefaultAudioArgs[mPlayerdefaultAudioArgs.length - 2] = "-quiet";
				mPlayerdefaultAudioArgs[mPlayerdefaultAudioArgs.length - 1] = "-quiet";
			}
		}

		ProcessWrapper mkfifo_process = audioP.getPipeProcess();

		mPlayerdefaultAudioArgs = finalizeTranscoderArgs(
			fileName,
			dlna,
			media,
			params,
			mPlayerdefaultAudioArgs
		);

		ProcessWrapperImpl pw = new ProcessWrapperImpl(mPlayerdefaultAudioArgs, params);
		pw.attachProcess(mkfifo_process);
		mkfifo_process.runInNewThread();

		try {
			Thread.sleep(100);
		} catch (InterruptedException e) { }

		audioP.deleteLater();
		pw.runInNewThread();

		try {
			Thread.sleep(100);
		} catch (InterruptedException e) { }

		return pw;
	}

	override
	public String mimeType() {
		return HTTPResource.AUDIO_TRANSCODE;
	}

	override
	public String name() {
		return "MPlayer Audio";
	}

	override
	public int type() {
		return Format.AUDIO;
	}

	override
	public JComponent config() {
		FormLayout layout = new FormLayout(
			"left:pref, 0:grow",
			"p, 3dlu, p, 3dlu, p, 3dlu, p, 3dlu, p, 3dlu, 0:grow"
		);
		PanelBuilder builder = new PanelBuilder(layout);
		builder.setBorder(Borders.EMPTY_BORDER);
		builder.setOpaque(false);

		CellConstraints cc = new CellConstraints();

		JComponent cmp = builder.addSeparator("Audio settings", cc.xyw(2, 1, 1));
		cmp = cast(JComponent) cmp.getComponent(0);
		cmp.setFont(cmp.getFont().deriveFont(Font.BOLD));

		noresample = new JCheckBox(Messages.getString("TrTab2.22"));
		noresample.setContentAreaFilled(false);
		noresample.setSelected(configuration.isAudioResample());
		noresample.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				configuration.setAudioResample(e.getStateChange() == ItemEvent.SELECTED);
			}
		});

		builder.add(noresample, cc.xy(2, 3));

		return builder.getPanel();
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public bool isCompatible(DLNAResource resource) {
		if (resource is null || resource.getFormat().getType() != Format.AUDIO) {
			return false;
		}

		Format format = resource.getFormat();

		if (format !is null) {
			Format.Identifier id = format.getIdentifier();

			if (id.opEquals(Format.Identifier.FLAC)
					|| id.opEquals(Format.Identifier.M4A)
					|| id.opEquals(Format.Identifier.OGG)
					|| id.opEquals(Format.Identifier.WAV)) {
				return true;
			}
		}

		return false;
	}
}
