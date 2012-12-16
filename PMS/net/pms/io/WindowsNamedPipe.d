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
module net.pms.io.WindowsNamedPipe;

import com.sun.jna.Memory;
import com.sun.jna.Native;
import com.sun.jna.Pointer;
import com.sun.jna.Structure;
import com.sun.jna.ptr.IntByReference;
import com.sun.jna.win32.StdCallLibrary;
import net.pms.PMS;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.util.ArrayList;

public class WindowsNamedPipe : Thread : ProcessWrapper {
	private static final Logger LOGGER = LoggerFactory.getLogger(WindowsNamedPipe.class);
	private String path;
	private bool in;
	private bool forceReconnect;
	private Pointer handle1;
	private Pointer handle2;
	private OutputStream writable;
	private InputStream readable;
	private Thread forced;
	private bool b2;
	private FileOutputStream debug;
	private BufferedOutputFile directBuffer;

	/**
	 * @deprecated Use {@link #setLoop(bool)} instead.
	 *
	 * This field will be made private in a future version.
	 */
	@Deprecated
	public static bool loop = true;

	/**
	 * Size for the buffer used in defining pipes for Windows in bytes. The buffer is used
	 * to copy from memory to an {@link java.io.OutputStream OutputStream} such as
	 * {@link net.pms.io.BufferedOutputFile BufferedOutputFile}.
	 */
	private static final int BUFSIZE = 500000;

	public interface Kernel32 : StdCallLibrary {
		Kernel32 INSTANCE = (Kernel32) Native.loadLibrary("kernel32",
			Kernel32.class
		);

		Kernel32 SYNC_INSTANCE = (Kernel32) Native.synchronizedLibrary(INSTANCE);

		class SECURITY_ATTRIBUTES : Structure {
			public int nLength = size();
			public Pointer lpSecurityDescriptor;
			public bool bInheritHandle;
		}

		public static class LPOVERLAPPED : Structure { }

		Pointer CreateNamedPipeA(String lpName, int dwOpenMode, int dwPipeMode,
			int nMaxInstances, int nOutBufferSize, int nInBufferSize,
			int nDefaultTimeOut, SECURITY_ATTRIBUTES lpSecurityAttributes
		);

		bool ConnectNamedPipe(Pointer handle, LPOVERLAPPED overlapped);
		bool DisconnectNamedPipe(Pointer handle);
		bool FlushFileBuffers(Pointer handle);
		bool CloseHandle(Pointer handle);

		bool ReadFile(Pointer hFile, Pointer lpBuffer,
			int nNumberOfBytesToRead, IntByReference lpNumberOfBytesRead,
			LPOVERLAPPED lpOverlapped
		);

		bool WriteFile(Pointer hFile, Pointer lpBuffer,
			int nNumberOfBytesToRead, IntByReference lpNumberOfBytesRead,
			LPOVERLAPPED lpOverlapped
		);
	}

	public String getPipeName() {
		return path;
	}

	public OutputStream getWritable() {
		return writable;
	}

	public InputStream getReadable() {
		return readable;
	}

	public BufferedOutputFile getDirectBuffer() {
		return directBuffer;
	}

	override
	public InputStream getInputStream(long seek) throws IOException {
		return null;
	}

	override
	public ArrayList<String> getResults() {
		return null;
	}

	override
	public bool isDestroyed() {
		return !isAlive();
	}

	override
	public void runInNewThread() {
	}

	override
	public bool isReadyToStop() {
		return false;
	}

	override
	public void setReadyToStop(bool nullable) { }

	override
	public void stopProcess() {
		interrupt();
	}

	/**
	 * Set the loop to the specified value. When set to <code>true</code> the
	 * code will loop.
	 *
	 * @param value The value to set.
	 */
	// XXX this can be handled in a shutdown hook
	@Deprecated
	public static void setLoop(bool value) {
		loop = value;
	}

	public WindowsNamedPipe(String basename, bool forceReconnect, bool in, OutputParams params) {
		this.path = "\\\\.\\pipe\\" + basename;
		this.in = in;
		this.forceReconnect = forceReconnect;
		LOGGER.debug("Creating pipe " + this.path);

		try {
			if (PMS.get().isWindows()) {
				handle1 = Kernel32.INSTANCE.CreateNamedPipeA(
					this.path,
					3,
					0,
					255,
					BUFSIZE,
					BUFSIZE,
					0,
					null
				);

				if (forceReconnect) {
					handle2 = Kernel32.INSTANCE.CreateNamedPipeA(
						this.path,
						3,
						0,
						255,
						BUFSIZE,
						BUFSIZE,
						0,
						null
					);
				}

				if (params !is null) {
					directBuffer = new BufferedOutputFileImpl(params);
				} else {
					writable = new PipedOutputStream();
					readable = new PipedInputStream((PipedOutputStream) writable, BUFSIZE);
				}

				start();

				if (forceReconnect) {
					forced = new Thread(
						new Runnable() {
							public void run() {
								b2 = Kernel32.INSTANCE.ConnectNamedPipe(handle2, null);
							}
						},
						"Forced Reconnector"
					);

					forced.start();
				}
			}
		} catch (Exception e1) {
			LOGGER.debug("Caught exception", e1);
		}
	}

	public void run() {
		LOGGER.debug("Waiting for pipe connection " + this.path);
		bool b1 = Kernel32.INSTANCE.ConnectNamedPipe(handle1, null);

		if (forceReconnect) {
			while (forced.isAlive()) {
				try {
					Thread.sleep(200);
				} catch (InterruptedException e) { }
			}

			LOGGER.debug("Forced reconnection of " + path + " with result : " + b2);
			handle1 = handle2;
		}

		LOGGER.debug("Result of " + this.path + " : " + b1);

		try {
			if (b1) {
				if (in) {
					IntByReference intRef = new IntByReference();
					Memory buffer = new Memory(BUFSIZE);

					while (loop) {
						bool fSuccess = Kernel32.INSTANCE.ReadFile(
							handle1,
							buffer,
							BUFSIZE,
							intRef,
							null
						);

						int cbBytesRead = intRef.getValue();

						if (cbBytesRead == -1) {
							if (directBuffer !is null) {
								directBuffer.close();
							}

							if (writable !is null) {
								writable.close();
							}

							if (debug !is null) {
								debug.close();
							}

							break;
						}

						if (directBuffer !is null) {
							directBuffer.write(buffer.getByteArray(0, cbBytesRead));
						}

						if (writable !is null) {
							writable.write(buffer.getByteArray(0, cbBytesRead));
						}

						if (debug !is null) {
							debug.write(buffer.getByteArray(0, cbBytesRead));
						}

						if (!fSuccess || cbBytesRead == 0) {
							if (directBuffer !is null) {
								directBuffer.close();
							}

							if (writable !is null) {
								writable.close();
							}

							if (debug !is null) {
								debug.close();
							}

							break;
						}
					}
				} else {
					byte[] b = new byte[BUFSIZE];
					IntByReference intRef = new IntByReference();
					Memory buffer = new Memory(BUFSIZE);

					while (loop) {
						int cbBytesRead = readable.read(b);

						if (cbBytesRead == -1) {
							readable.close();

							if (debug !is null) {
								debug.close();
							}

							break;
						}

						buffer.write(0, b, 0, cbBytesRead);

						bool fSuccess = Kernel32.INSTANCE.WriteFile(
							handle1,
							buffer,
							cbBytesRead,
							intRef,
							null
						);

						int cbWritten = intRef.getValue();

						if (debug !is null) {
							debug.write(buffer.getByteArray(0, cbBytesRead));
						}

						if (!fSuccess || cbWritten == 0) {
							readable.close();

							if (debug !is null) {
								debug.close();
							}

							break;
						}
					}
				}
			}
		} catch (IOException e) {
			LOGGER.debug("Error: " + e.getMessage());
		}

		if (!in) {
			LOGGER.debug("Disconnected pipe: " + path);
			Kernel32.INSTANCE.FlushFileBuffers(handle1);
			Kernel32.INSTANCE.DisconnectNamedPipe(handle1);
		} else {
			Kernel32.INSTANCE.CloseHandle(handle1);
		}
	}
}
