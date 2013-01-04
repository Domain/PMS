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
module net.pms.io.WaitBufferedInputStream;

import java.lang.exceptions;
import java.io.InputStream;

class WaitBufferedInputStream : InputStream {
	private BufferedOutputFile outputStream;
	private long readCount;
	private bool firstRead;

	public void setReadCount(long readCount) {
		this.readCount = readCount;
	}

	public long getReadCount() {
		return readCount;
	}
	
	this(BufferedOutputFile outputStream) {
		this.outputStream = outputStream;
		firstRead = true;
	}

	public int read() {
		int r = outputStream.read(firstRead, getReadCount());
		if (r != -1) {
			setReadCount(getReadCount() + 1);
		}
		firstRead = false;
		return r;
	}

	override
	public int read(byte[] b, int off, int len) {
		int returned = outputStream.read(firstRead, getReadCount(), b, off, len);
		if (returned != -1) {
			setReadCount(getReadCount() + returned);
		}
		firstRead = false;
		return returned;
	}

	override
	public int read(byte[] b) {
		return read(b, 0, b.length);
	}

	public int available() {
		return cast(int) outputStream.getWriteCount();
	}

	public void close() {
		outputStream.removeInputStream(this);
		outputStream.detachInputStream();
	}
}

