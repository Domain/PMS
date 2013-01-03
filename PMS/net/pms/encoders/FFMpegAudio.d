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
module net.pms.encoders.FFMpegAudio;

////import com.jgoodies.forms.builder.PanelBuilder;
////import com.jgoodies.forms.factories.Borders;
////import com.jgoodies.forms.layout.CellConstraints;
////import com.jgoodies.forms.layout.FormLayout;

import net.pms.configuration.PmsConfiguration;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.dlna.DLNAResource;
import net.pms.formats.Format;
import net.pms.io.OutputParams;
import net.pms.io.ProcessWrapper;
import net.pms.io.ProcessWrapperImpl;
import net.pms.Messages;
import net.pms.network.HTTPResource;
import net.pms.PMS;

////import java.awt.*;
//import java.awt.event.ItemEvent;
//import java.awt.event.ItemListener;
import java.lang.exceptions;
import java.util.ArrayList;
import java.util.List;
////import javax.swing.*;

public class FFMpegAudio : FFMpegVideo {
	public static const String ID = "ffmpegaudio";
	private immutable PmsConfiguration configuration;

	// should be private
	deprecated
	JCheckBox noresample;

	public this(PmsConfiguration configuration) {
		this.configuration = configuration;
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

	override
	public int purpose() {
		return AUDIO_SIMPLEFILE_PLAYER;
	}

	override
	public String id() {
		return ID;
	}

	// FIXME why is this false if launchTranscode supports it (-ss)?
	override
	public bool isTimeSeekable() {
		return false;
	}

	public bool avisynth() {
		return false;
	}

	override
	public String name() {
		return "FFmpeg Audio";
	}

	override
	public int type() {
		return Format.AUDIO;
	}

	override
	deprecated
	public String[] args() {
		// unused: kept for backwards compatibility
		return [ "-f", "s16be", "-ar", "48000" ];
	}

	override
	public String mimeType() {
		return HTTPResource.AUDIO_TRANSCODE;
	}

	override
	public ProcessWrapper launchTranscode(
		String fileName,
		DLNAResource dlna,
		DLNAMediaInfo media,
		OutputParams params
	) {
		params.maxBufferSize = configuration.getMaxAudioBuffer();
		params.waitbeforestart = 2000;
		params.manageFastStart();

		int nThreads = configuration.getNumberOfCpuCores();
		List/*<String>*/ cmdList = new ArrayList/*<String>*/();

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

		if (params.mediaRenderer.isTranscodeToMP3()) {
			cmdList.add("-f");
			cmdList.add("mp3");
			cmdList.add("-ab");
			cmdList.add("320000");
		} else if (params.mediaRenderer.isTranscodeToWAV()) {
			cmdList.add("-f");
			cmdList.add("wav");
		} else { // default: LPCM
			cmdList.add("-f");
			cmdList.add("s16be"); // same as -f wav, but without a WAV header
		}

		if (configuration.isAudioResample()) {
			if (params.mediaRenderer.isTranscodeAudioTo441()) {
				cmdList.add("-ar");
				cmdList.add("44100");
			} else {
				cmdList.add("-ar");
				cmdList.add("48000");
			}
		}

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
