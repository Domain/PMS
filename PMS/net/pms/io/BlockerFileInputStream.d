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
module net.pms.io.BlockerFileInputStream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

deprecated
// no longer used
public class BlockerFileInputStream : UnusedInputStream {
	private static immutable Logger logger = LoggerFactory.getLogger!BlockerFileInputStream();
	private static const int CHECK_INTERVAL = 1000;
	private long readCount;
	private long waitSize;
	private File file;
	private bool firstRead;

	public this(ProcessWrapper pw, File file, double waitSize) {
		super(new FileInputStream(file), pw, 2000);
		this.file = file;
		this.waitSize = (long) (waitSize * 1048576);
		firstRead = true;
	}

	override
	public int read() {
		if (checkAvailability()) {
			readCount++;
			int r = super.read();
			firstRead = false;
			return r;
		} else {
			return -1;
		}
	}

	private bool checkAvailability() {
		if (readCount > file.length()) {
			logger._debug("File " ~ file.getAbsolutePath() ~ " is not that long!: " ~ readCount);
			return false;
		}
		int c = 0;
		long writeCount = file.length();
		long wait = firstRead ? waitSize : 100000;
		while (writeCount - readCount <= wait && c < 15) {
			if (c == 0) {
				logger.trace("Suspend File Read: readCount=" ~ readCount.toString() ~ " / writeCount=" ~ writeCount.toString());
			}
			c++;
			try {
				Thread.sleep(CHECK_INTERVAL);
			} catch (InterruptedException e) {
			}
			writeCount = file.length();
		}

		if (c > 0) {
			logger.trace("Resume Read: readCount=" ~ readCount.toString() ~ " / writeCount=" ~ file.length().toString());
		}
		return true;
	}

	public int available() {
		return super.available();
	}

	public void close() {
		super.close();
	}

	public long skip(long n) {
		long l = super.skip(n);
		readCount += l;
		return l;
	}

	override
	public int read(byte[] b, int off, int len) {
		if (checkAvailability()) {
			int r = super.read(b, off, len);
			firstRead = false;
			readCount += r;
			return r;
		} else {
			return -1;
		}
	}

	override
	public void unusedStreamSignal() {
		if (!file._delete()) {
			logger._debug("Failed to delete \"" ~ file.getAbsolutePath() ~ "\"");
		}
	}
}
