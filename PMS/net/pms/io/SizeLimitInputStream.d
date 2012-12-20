module net.pms.io.SizeLimitInputStream;

/*
 * Input stream wrapper with a byte limit.
 * Copyright (C) 2004 Stephen Ostermiller
 * http://ostermiller.org/contact.pl?regarding=Java+Utilities
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * See COPYING.TXT for details.
 */

import java.io.IOException;
import java.io.InputStream;

/**
 * An input stream wrapper that will read only a set number of bytes from the
 * underlying stream.
 * 
 * @author Stephen Ostermiller
 *         http://ostermiller.org/contact.pl?regarding=Java+Utilities
 * @since ostermillerutils 1.04.00
 */
public class SizeLimitInputStream : InputStream {

	/**
	 * The input stream that is being protected. All methods should be forwarded
	 * to it, after checking the size that has been read.
	 * 
	 * @since ostermillerutils 1.04.00
	 */
	protected InputStream _in;

	/**
	 * The number of bytes to read at most from this Stream. Read methods should
	 * check to ensure that bytesRead never exceeds maxBytesToRead.
	 * 
	 * @since ostermillerutils 1.04.00
	 */
	protected long maxBytesToRead = 0;

	/**
	 * The number of bytes that have been read from this stream. Read methods
	 * should check to ensure that bytesRead never exceeds maxBytesToRead.
	 * 
	 * @since ostermillerutils 1.04.00
	 */
	protected long bytesRead = 0;

	/**
	 * The number of bytes that have been read from this stream since mark() was
	 * called.
	 * 
	 * @since ostermillerutils 1.04.00
	 */
	protected long bytesReadSinceMark = 0;

	/**
	 * The number of bytes the user has request to have been marked for reset.
	 * 
	 * @since ostermillerutils 1.04.00
	 */
	protected long markReadLimitBytes = -1;

	/**
	 * Get the number of bytes actually read from this stream.
	 * 
	 * @return number of bytes that have already been taken from this stream.
	 * 
	 * @since ostermillerutils 1.04.00
	 */
	public long getBytesRead() {
		return bytesRead;
	}

	/**
	 * Get the maximum number of bytes left to read before the limit (set in the
	 * constructor) is reached.
	 * 
	 * @return The number of bytes that (at a maximum) are left to be taken from
	 *         this stream.
	 * 
	 * @since ostermillerutils 1.04.00
	 */
	public long getBytesLeft() {
		return maxBytesToRead - bytesRead;
	}

	/**
	 * Tell whether the number of bytes specified _in the constructor have been
	 * read yet.
	 * 
	 * @return true iff the specified number of bytes have all been read.
	 * 
	 * @since ostermillerutils 1.04.00
	 */
	public bool allBytesRead() {
		return getBytesLeft() == 0;
	}

	/**
	 * Get the number of total bytes (including bytes already read) that can be
	 * read from this stream (as set in the constructor).
	 * 
	 * @return Maximum bytes that can be read until the size limit runs out
	 * 
	 * @since ostermillerutils 1.04.00
	 */
	public long getMaxBytesToRead() {
		return maxBytesToRead;
	}

	/**
	 * Create a new size limit input stream from another stream given a size
	 * limit.
	 * 
	 * @param _in
	 *            The input stream.
	 * @param maxBytesToRead
	 *            the max number of bytes to allow to be read from the
	 *            underlying stream.
	 * 
	 * @since ostermillerutils 1.04.00
	 */
	public this(InputStream _in, long maxBytesToRead) {
		this._in = _in;
		this.maxBytesToRead = maxBytesToRead;
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public int read() {
		if (bytesRead >= maxBytesToRead) {
			return -1;
		}
		int b = _in.read();
		if (b != -1) {
			bytesRead++;
			bytesReadSinceMark++;
		}
		return b;
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public int read(byte[] b) {
		return this.read(b, 0, b.length);
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public int read(byte[] b, int off, int len) {
		if (bytesRead >= maxBytesToRead) {
			return -1;
		}
		long bytesLeft = getBytesLeft();
		if (len > bytesLeft) {
			len = cast(int) bytesLeft;
		}
		int bytesJustRead = _in.read(b, off, len);
		bytesRead += bytesJustRead;
		bytesReadSinceMark += bytesJustRead;
		return bytesJustRead;
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public long skip(long n) {
		if (bytesRead >= maxBytesToRead) {
			return -1;
		}
		long bytesLeft = getBytesLeft();
		if (n > bytesLeft) {
			n = bytesLeft;
		}
		return _in.skip(n);
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public int available() {
		int available = _in.available();
		long bytesLeft = getBytesLeft();
		if (available > bytesLeft) {
			available = cast(int) bytesLeft;
		}
		return available;
	}

	/**
	 * Close this stream and underlying streams. Calling this method may make
	 * data on the underlying stream unavailable.
	 * <p>
	 * Consider wrapping this stream _in a NoCloseStream so that clients can call
	 * close() with no effect.
	 * 
	 * @since ostermillerutils 1.04.00
	 */
	override
	public void close() {
		_in.close();
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public void mark(int readlimit) {
		if (_in.markSupported()) {
			markReadLimitBytes = readlimit;
			bytesReadSinceMark = 0;
			_in.mark(readlimit);
		}
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public void reset() {
		if (_in.markSupported() && bytesReadSinceMark <= markReadLimitBytes) {
			bytesRead -= bytesReadSinceMark;
			_in.reset();
			bytesReadSinceMark = 0;
		}
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public bool markSupported() {
		return _in.markSupported();
	}
}

