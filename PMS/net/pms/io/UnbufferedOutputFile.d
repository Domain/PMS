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
module net.pms.io.UnbufferedOutputFile;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.exceptions;
import java.io.InputStream;
import java.io.PipedInputStream;
import java.io.PipedOutputStream;


/**
 * Utility class to transport bytes from a transcoding process to a DLNA client. Unlike
 * {@link BufferedOutputFileImpl}, no attempt is made to buffer the output. Instead,
 * {@link java.io.PipedOutputStream PipedOutputStream} and {@link java.io.PipedInputStream
 * PipedInputStream} are used to pump data from the transcoder to the client. The idea is
 * to have as little interference as possible in the piping process, allowing PMS to be
 * agnostic of the transcoded data and focus on steering the process and handling requests
 * instead.
 * <p>
 * TODO: Since no data is buffered, seek requests should be not be delegated to this
 * class. This class can only be used for straightforward streaming. Instead, the
 * current process should be stopped (killed) and a new process should be started.
 * This has not been implemented yet, so seeking is not an option right now. 
 * <p>
 * Because of the missing feature, this class is currently not used anywhere in PMS. If
 * you want to experiment with it, search for "new BufferedOutputFileImpl(" and replace it
 * with "new UnbufferedOutputFile(" in the classes {@link OutputBufferConsumer} and
 * {@link WindowsNamedPipe}.
 */
public class UnbufferedOutputFile : BufferedOutputFile {

	private static immutable Logger LOGGER = LoggerFactory.getLogger!UnbufferedOutputFile();
	
	private PipedOutputStream pipedOutputStream;
	private PipedInputStream pipedInputStream;
	
	public this(OutputParams params) {
		pipedOutputStream = new PipedOutputStream();
		
		try {
			pipedInputStream = new PipedInputStream(pipedOutputStream);
		} catch (IOException e) {
			logger._debug("Error creating piped input stream: " ~ e.toString());
		}
	}
	
	/**
	 * Closes the piped streams and releases any system resources associated with
	 * them. This object may no longer be used for writing bytes.
	 */
	override
	public void close() {
		pipedInputStream.close();
		pipedOutputStream.close();
	}

	/**
	 * Returns the {@link java.io.PipedInputStream PipedInputStream} connected to the
	 * transcoding output stream as is, ignoring the newReadposition parameter.
	 * @param newReadPosition This parameter is ignored.
	 * @return The piped input stream
	 */
	override
	public InputStream getInputStream(long newReadPosition) {
		return pipedInputStream;
	}

	/**
	 * Writes len bytes from the specified byte array starting at offset off to
	 * the piped output stream.
	 *  
	 * @param b The data
	 * @param off The start offset in the data
	 * @param len The number of bytes to write
	 */
	override
	public void write(byte[] b, int off, int len) {
		pipedOutputStream.write(b, off, len);
	}
	
	/**
	 * Writes the specified byte to the piped output stream.
	 * 
	 * @param b The byte to write
	 */
	override
	public void write(int b) {
		pipedOutputStream.write(b);
	}

	/**
	 * Writes b.length bytes from the specified byte array to this output stream. The
	 * general contract for <code>write(b)</code> is that it should have exactly the
	 * same effect as the call <code>write(b, 0, b.length)</code>.
	 * @param byteArray
	 */
	override
	public void write(byte[] byteArray) {
		pipedOutputStream.write(byteArray);
	}
	
	/**
	 * @deprecated Unused method from interface.
	 * @return null
	 */
	deprecated
	public WaitBufferedInputStream getCurrentInputStream() {
		return null;
	}
	
	/**
	 * @deprecated Unused method from interface.
	 * @return 0
	 */
	deprecated
	public long getWriteCount() {
		return 0;
	}
	
	/**
	 * @deprecated Unused method from interface.
	 * @return 0
	 */
	deprecated
	public int read(bool firstRead, long readCount) {
		return 0;
	}

	/**
	 * @deprecated Unused method from interface.
	 * @return 0
	 */
	deprecated
	public int read(bool firstRead, long readCount, byte[] b, int off, int len) {
		return 0;
	}
	
	/**
	 * @deprecated Unused method from interface.
	 */
	deprecated
	public void attachThread(ProcessWrapper thread) {
	}
	
	/**
	 * @deprecated Unused method from interface.
	 */
	deprecated
	public void reset() {
	}
	
	/**
	 * @deprecated Unused method from interface.
	 */
	deprecated
	public void removeInputStream(WaitBufferedInputStream waitBufferedInputStream) {
	}

	
	/**
	 * @deprecated Unused method from interface.
	 */
	deprecated
	public void detachInputStream() {
	}
}
