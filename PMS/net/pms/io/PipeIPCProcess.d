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
module net.pms.io.PipeIPCProcess;

import com.sun.jna.Platform;
import net.pms.util.DTSAudioOutputStream;
import net.pms.util.H264AnnexBInputStream;
import net.pms.util.PCMAudioOutputStream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.exceptions;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;

public class PipeIPCProcess : Thread , ProcessWrapper {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!PipeIPCProcess();
	private PipeProcess mkin;
	private PipeProcess mkout;
	private StreamModifier modifier;

	public StreamModifier getModifier() {
		return modifier;
	}

	public void setModifier(StreamModifier modifier) {
		this.modifier = modifier;
	}

	public this(String pipeName, String pipeNameOut, bool forcereconnect1, bool forcereconnect2) {
		mkin = new PipeProcess(pipeName, forcereconnect1 ? "reconnect" : "dummy");
		mkout = new PipeProcess(pipeNameOut, "out", forcereconnect2 ? "reconnect" : "dummy");
	}

	public void run() {
		byte[] b = new byte[512 * 1024];
		int n = -1;
		InputStream _in = null;
		OutputStream _out = null;
		OutputStream _debug = null;

		try {
			_in = mkin.getInputStream();
			_out = mkout.getOutputStream();

			if (modifier !is null && modifier.isH264AnnexB()) {
				_in = new H264AnnexBInputStream(_in, modifier.getHeader());
			} else if (modifier !is null && modifier.isDtsEmbed()) {
				_out = new DTSAudioOutputStream(new PCMAudioOutputStream(_out, modifier.getNbChannels(), modifier.getSampleFrequency(), modifier.getBitsPerSample()));
			} else if (modifier !is null && modifier.isPcm()) {
				_out = new PCMAudioOutputStream(_out, modifier.getNbChannels(), modifier.getSampleFrequency(), modifier.getBitsPerSample());
			}

			if (modifier !is null && modifier.getHeader() !is null && !modifier.isH264AnnexB()) {
				_out.write(modifier.getHeader());
			}

			while ((n = _in.read(b)) > -1) {
				_out.write(b, 0, n);
				if (_debug !is null) {
					_debug.write(b, 0, n);
				}
			}
		} catch (IOException e) {
			logger._debug("Error :" ~ e.getMessage());
		} finally {
			try {
				// in and out may not have been initialized:
				// http://ps3mediaserver.org/forum/viewtopic.php?f=6&t=9885&view=unread#p45142
				if (_in !is null) {
					_in.close();
				}
				if (_out !is null) {
					_out.close();
				}
				if (_debug !is null) {
					_debug.close();
				}
			} catch (IOException e) {
				logger._debug("Error :" ~ e.getMessage());
			}
		}
	}

	public String getInputPipe() {
		return mkin.getInputPipe();
	}

	public String getOutputPipe() {
		return mkout.getOutputPipe();
	}

	public ProcessWrapper getPipeProcess() {
		return this;
	}

	public void deleteLater() {
		mkin.deleteLater();
		mkout.deleteLater();
	}

	public InputStream getInputStream() {
		return mkin.getInputStream();
	}

	public OutputStream getOutputStream() {
		return mkout.getOutputStream();
	}

	override
	public InputStream getInputStream(long seek) {
		return null;
	}

	override
	public ArrayList/*<String>*/ getResults() {
		return null;
	}

	override
	public bool isDestroyed() {
		return isAlive();
	}

	override
	public void runInNewThread() {
		if (!Platform.isWindows()) {
			mkin.getPipeProcess().runInNewThread();
			mkout.getPipeProcess().runInNewThread();
			try {
				Thread.sleep(150);
			} catch (InterruptedException e) {
			}
		}
		start();
	}

	override
	public bool isReadyToStop() {
		return false;
	}

	override
	public void setReadyToStop(bool nullable) {
	}

	override
	public void stopProcess() {
		this.interrupt();
		mkin.getPipeProcess().stopProcess();
		mkout.getPipeProcess().stopProcess();
	}
}
