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
module net.pms.encoders.MPlayerWebVideoDump;

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

import java.io.IOException;

public class MPlayerWebVideoDump : MPlayerAudio {
	public this(PmsConfiguration configuration) {
		super(configuration);
	}
	public static const String ID = "mplayervideodump";

	override
	public JComponent config() {
		return null;
	}

	override
	public int purpose() {
		return VIDEO_WEBSTREAM_PLAYER;
	}

	override
	public String id() {
		return ID;
	}

	override
	public ProcessWrapper launchTranscode(String fileName, DLNAResource dlna, DLNAMediaInfo media,
		OutputParams params) {
		params.minBufferSize = params.minFileSize;
		params.secondread_minsize = 100000;
		params.waitbeforestart = 6000;
		params.maxBufferSize = PMS.getConfiguration().getMaxAudioBuffer();
		PipeProcess audioP = new PipeProcess("mplayer_webvid" ~ System.currentTimeMillis());

		String[] mPlayerdefaultAudioArgs = [ PMS.getConfiguration().getMplayerPath(), fileName, "-nocache", "-dumpstream", "-quiet", "-dumpfile", audioP.getInputPipe()];
		params.input_pipes[0] = audioP;

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
			Thread.sleep(300);
		} catch (InterruptedException e) {
		}

		audioP.deleteLater();
		pw.runInNewThread();
		try {
			Thread.sleep(300);
		} catch (InterruptedException e) {
		}
		return pw;
	}

	override
	public String mimeType() {
		return HTTPResource.VIDEO_TRANSCODE;
	}

	override
	public String name() {
		return "MPlayer Video Dump";
	}

	override
	public int type() {
		return Format.VIDEO;
	}

	override
	public bool isTimeSeekable() {
		return false;
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public bool isCompatible(DLNAResource resource) {
		if (resource is null || resource.getFormat().getType() != Format.VIDEO) {
			return false;
		}

		Format format = resource.getFormat();

		if (format !is null) {
			Format.Identifier id = format.getIdentifier();

			if (id.equals(Format.Identifier.WEB)) {
				return true;
			}
		}

		return false;
	}
}
