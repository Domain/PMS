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
module net.pms.io.UnusedInputStream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.exceptions;
import java.io.InputStream;

public abstract class UnusedInputStream : InputStream {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!UnusedInputStream();
	private InputStream inputStream;
	private UnusedProcess processToTerminate;
	private int timeout;

	public this(InputStream inputStream, UnusedProcess processToTerminate, int timeout) {
		this.inputStream = inputStream;
		this.processToTerminate = processToTerminate;
		this.timeout = timeout;
		processToTerminate.setReadyToStop(false);
	}

	public int available() {
		return inputStream.available();
	}

	public void close() {
		inputStream.close();
		if (processToTerminate !is null) {
			processToTerminate.setReadyToStop(true);
		}
		Runnable checkEnd = dgRunnable( {
			try {
				Thread.sleep(timeout);
			} catch (InterruptedException e) {
				logger.error(null, e);
			}
			if (processToTerminate !is null && processToTerminate.isReadyToStop()) {
				logger._debug("Destroying / Stopping attached process: " ~ processToTerminate);
				if (processToTerminate !is null) {
					processToTerminate.stopProcess();
				}
				processToTerminate = null;
				unusedStreamSignal();
			}
		});
		(new Thread(checkEnd, "Process Reaper")).start();
	}

	public int read() {
		return inputStream.read();
	}

	public int read(byte[] b, int off, int len) {
		return inputStream.read(b, off, len);
	}

	public long skip(long n) {
		return inputStream.skip(n);
	}

	public String toString() {
		return inputStream.toString();
	}

	public abstract void unusedStreamSignal();
}
