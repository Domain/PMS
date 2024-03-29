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
module net.pms.io.BufferedOutputFileImpl;

import net.pms.Messages;
import net.pms.PMS;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.FileOutputStream;
import java.lang.exceptions;
import java.io.InputStream;
import java.io.OutputStream;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;

/**
 * Circular memory buffer that can be used as {@link java.io.OutputStream OutputStream} and
 * provides methods that can read data from the memory buffer using an
 * {@link java.io.InputStream InputStream}. The name of this class is a bit misleading, as
 * there is typically no file involved in the process at all. Instead, the buffer is
 * typically used to hold data piped by a transcoding process in one thread until a request
 * for data comes in from another thread.
 * 
 * @see net.pms.io.ProcessWrapperImpl
 * @see net.pms.network.Request Request
 * @see net.pms.network.RequestV2 RequestV2
 */
public class BufferedOutputFileImpl : OutputStream , BufferedOutputFile {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!BufferedOutputFileImpl();
	
	/**
	 * Initial size for the buffer in bytes.
	 */
	private static const int INITIAL_BUFFER_SIZE = 50000000;
	
	/**
	 * Amount of extra bytes to increase the initial buffer with when memory allocation fails.
	 */
	private static const int MARGIN_LARGE = 20000000;
	private static const int MARGIN_MEDIUM = 2000000;
	private static const int MARGIN_SMALL = 600000;
	
	private static const int CHECK_INTERVAL = 500;
	private static const int CHECK_END_OF_PROCESS = 2500; // must be superior to CHECK_INTERVAL
	private int minMemorySize;
	private int maxMemorySize;
	private int bufferOverflowWarning;
	private bool eof;
	private long writeCount;
	private byte[] buffer;
	private bool forcefirst = (PMS.getConfiguration().getTrancodeBlocksMultipleConnections() && PMS.getConfiguration().getTrancodeKeepFirstConnections());
	private ArrayList/*<WaitBufferedInputStream>*/ inputStreams;
	private ProcessWrapper attachedThread;
	private int secondread_minsize;
	private Timer timer;
	private bool shiftScr;
	private FileOutputStream debugOutput = null;
	private bool buffered = false;
	private DecimalFormat formatter = new DecimalFormat("#,###");
	private double timeseek;
	private double timeend;
	private long packetpos = 0;

	/**
	 * Try to increase the size of a memory buffer, while retaining its contents. The
	 * provided new size is considered to be a request, it is scaled down when an
	 * OutOfMemory error occurs. There is no guarantee about the exact length of the
	 * returned byte array, only that it is greater than or equal to the original buffer
	 * size. When null is passed as an argument, a fresh buffer will be allocated.
	 * Copying one byte array to another is a costly operation, both in memory usage
	 * and performance. It is best to avoid using this method.
	 * 
	 * @param buffer The byte array to resize, null is allowed.
	 * @param newSize The requested final size. Should be greater than the original size
	 * or the original buffer will be returned. 
	 * @return The resized byte array.
	 */
	private byte[] growBuffer(byte[] buffer, int newSize) {
		byte[] copy;
		
		if (buffer is null) {
			// Temporary empty array to avoid null tests in the code below
			buffer = new byte[0];
		}
		
		if (newSize <= buffer.length) {
			// Cannot shrink the original
			return buffer;
		}
		
		try {
			// Try to allocate the requested new size
			copy = new byte[newSize];
		} catch (OutOfMemoryError e) {
			if (buffer.length == 0) {
				LOGGER.trace("Cannot initialize buffer to " ~ formatter.format(newSize) ~ " bytes.");
			} else {
				LOGGER._debug("Cannot grow buffer size from " ~ formatter.format(buffer.length) ~ " bytes to " + formatter.format(newSize) ~ " bytes.");
				
			}

			// Could not allocate the requested new size, use 30% of free memory instead.
			// Rationale behind using 30%: multiple threads are running at the same time,
			// we do not want one threads memory usage to suffocate the others.
			// Using maxMemory() to ignore the initial Java heap space size that freeMemory()
			// takes into account.
			// See http://javarevisited.blogspot.com/2011/05/java-heap-space-memory-size-jvm.html
			long realisticSize = Runtime.getRuntime().maxMemory() * 3 / 10;
			
			if (realisticSize < buffer.length) {
				// A copy would be smaller in size, shrinking instead of growing the buffer.
				// Better to return the original and retain its size.
				return buffer;
			} else {
				try {
					// Try to allocate the realistic alternative size
					copy = new byte[cast(int) realisticSize];
				} catch (OutOfMemoryError e2) {
					LOGGER._debug("Cannot grow buffer size from " ~ formatter.format(buffer.length) ~ " bytes to "
							~ formatter.format(realisticSize) ~ " bytes either.");
					LOGGER.trace("freeMemory: " ~ formatter.format(Runtime.getRuntime().freeMemory()));
					LOGGER.trace("totalMemory: " ~ formatter.format(Runtime.getRuntime().totalMemory()));
					LOGGER.trace("maxMemory: " ~ formatter.format(Runtime.getRuntime().maxMemory()));

					// Cannot allocate memory, no other option than to return the original.
					return buffer;
				}
			}
		}

		if (buffer.length == 0) {
			LOGGER.trace("Successfully initialized buffer to " ~ formatter.format(copy.length) ~ " bytes.");
		} else {
			try {
				System.arraycopy(buffer, 0, copy, 0, buffer.length);
				LOGGER.trace("Successfully grown buffer from " ~ formatter.format(buffer.length) ~ " bytes to "
						~ formatter.format(copy.length) ~ " bytes."); 
			} catch (NullPointerException npe) {
				LOGGER.trace("Cannot grow buffer size, error copying buffer contents.");
			}
		}

		return copy;
	}
	
	/**
	 * Constructor to create a memory buffer based on settings that are passed on. Will also
	 * start up a timer task to display buffer size and usage in the PMS main screen.
	 * 
	 * @param params {@link net.pms.io.OutputParams} object that contains preferences for the buffers
	 * 				dimensions and behavior.
	 */
	public this(OutputParams params) {
		this.minMemorySize = cast(int) (1048576 * params.minBufferSize);
		this.maxMemorySize = cast(int) (1048576 * params.maxBufferSize);

		// FIXME: Better to relate margin directly to maxMemorySize instead of using arbitrary fixed values

		int margin = MARGIN_LARGE; // Issue 220: : to 20Mb : readCount is wrongly set cause of the ps3's
		// 2nd request with a range like 44-xxx, causing the end of buffer margin to be first sent 
		if (this.maxMemorySize < margin) {// for thumbnails / small buffer usage
			margin = MARGIN_MEDIUM; // margin must be superior to the buffer size of OutputBufferConsumer or direct buffer size from WindowsNamedPipe class
			if (this.maxMemorySize < margin) {
				margin = MARGIN_SMALL;
			}
		}
		this.bufferOverflowWarning = this.maxMemorySize - margin;
		this.secondread_minsize = params.secondread_minsize;
		this.timeseek = params.timeseek;
		this.timeend = params.timeend;
		this.shiftScr = params.shift_scr;

		if ((maxMemorySize > INITIAL_BUFFER_SIZE) && 
			!PMS.getConfiguration().initBufferMax()) {
			// Try to limit memory usage a bit.
			// Start with a modest allocation initially, grow to max when needed later.
			buffer = growBuffer(null, INITIAL_BUFFER_SIZE);
		} else {
			buffer = growBuffer(null, maxMemorySize);
		}

		if (buffer.length == 0) {
			// Cannot transcode without a buffer
			LOGGER.info("FATAL ERROR: OutOfMemory / dumping stats");
			LOGGER.trace("freeMemory: " ~ Runtime.getRuntime().freeMemory());
			LOGGER.trace("totalMemory: " ~ Runtime.getRuntime().totalMemory());
			LOGGER.trace("maxMemory: " ~ Runtime.getRuntime().maxMemory());
			System.exit(1);			
		}
		
		inputStreams = new ArrayList/*<WaitBufferedInputStream>*/();
		timer = new Timer();
		if (params.maxBufferSize > 15 && !params.hidebuffer) {
			timer.schedule(new class() TimerTask {
				public void run() {
					long rc = 0;
					if (getCurrentInputStream() !is null) {
						rc = getCurrentInputStream().getReadCount();
						PMS.get().getFrame().setReadValue(rc, "");
					}
					long space = (writeCount - rc);
					LOGGER.trace("buffered: " ~ formatter.format(space) ~ " bytes / inputs: " ~ inputStreams.size());
					
					// There are 1048576 bytes in a megabyte
					long bufferInMBs = space / 1048576;

					PMS.get().getFrame().setValue(cast(int) (100 * space / maxMemorySize), formatter.format(bufferInMBs) ~ " " ~ Messages.getString("StatusTab.12"));
				}
			}, 0, 2000);
		}
	}

	override
	public void close() {
		LOGGER.trace("EOF");
		eof = true;
	}

	override
	public WaitBufferedInputStream getCurrentInputStream() {
		WaitBufferedInputStream wai = null;

		if (inputStreams.size() > 0) {
			try {
				wai = forcefirst ? inputStreams.get(0) : inputStreams.get(inputStreams.size() - 1);
			} catch (IndexOutOfBoundsException e) {
				// this should never happen unless there's a concurrency issue,
				// so log it if it does
				LOGGER.error("Unexpected input stream removal", e);
			}
		}

		return wai;
	}
	
	override
	public InputStream getInputStream(long newReadPosition) {
		if (attachedThread !is null) {
			attachedThread.setReadyToStop(false);
		}
		WaitBufferedInputStream atominputStream = null;
		if (!PMS.getConfiguration().getTrancodeBlocksMultipleConnections() || getCurrentInputStream() is null) {
			atominputStream = new WaitBufferedInputStream(this);
			inputStreams.add(atominputStream);
		} else {
			if (PMS.getConfiguration().getTrancodeKeepFirstConnections()) {
				LOGGER._debug("BufferedOutputFile is already attached to an InputStream: " ~ getCurrentInputStream());
			} else {
				// Ditlew - fixes the above (the above iterator breaks on items getting close, cause they will remove them self from the arraylist)
				while (inputStreams.size() > 0) {
					try {
						inputStreams.get(0).close();
					} catch (IOException e) {
						LOGGER.error("Error: ", e);
					}
				}

				inputStreams.clear();
				atominputStream = new WaitBufferedInputStream(this);
				inputStreams.add(atominputStream);
				LOGGER._debug("Reassign inputstream: " ~ getCurrentInputStream());
			}
			return null;
		}
		if (newReadPosition > 0) {
			LOGGER._debug("Setting InputStream new position to: " ~ formatter.format(newReadPosition));
			atominputStream.setReadCount(newReadPosition);
		}
		return atominputStream;
	}

	override
	public long getWriteCount() {
		return writeCount;
	}

	override
	public void write(byte[] b, int off, int len) {
		if (debugOutput !is null) {
			debugOutput.write(b, off, len);
			debugOutput.flush();
		}
		
		WaitBufferedInputStream input = getCurrentInputStream();

		//LOGGER.trace("write(" + b.length + ", " + off + ", " + len + "), writeCount = " + writeCount + ", readCount = " + (input !is null ? input.getReadCount() : "null"));

		while ((input !is null && (writeCount - input.getReadCount() > bufferOverflowWarning)) || (input is null && writeCount > bufferOverflowWarning)) {
			try {
				Thread.sleep(CHECK_INTERVAL);
			} catch (InterruptedException e) {
			}
			input = getCurrentInputStream();
		}
		
		
		if (buffer !is null) {
			int mb = cast(int) (writeCount % maxMemorySize);

			if (mb >= buffer.length - (len - off)) {
				if (buffer.length == INITIAL_BUFFER_SIZE) {
					// Initial buffer size was not big enough, try to increase it
					buffer = growBuffer(buffer, maxMemorySize);
				}

				// FIXME: This smells like 2x System.arraycopy()!
				int s = (len - off);
				for (int i = 0; i < s; i++) {
					buffer[modulo(mb + i, buffer.length)] = b[off + i];
				}
			} else {
				System.arraycopy(b, off, buffer, mb, (len - off));
				if ((len - off) > 0) {
					buffered = true;
				}
			}

			// Ditlew - WDTV Live
			if (timeseek > 0 && writeCount > 10) {
				for (int i = 0; i < len; i++) {
					if (buffer !is null && shiftScr) {
						shiftSCRByTimeSeek(mb + i, cast(int) timeseek); // Ditlew - update any SCR headers
					}					//shiftGOPByTimeSeek(mb+i, (int)timeseek); // Ditlew - update any GOP headers - Not needed for WDTV Live
				}
			}

			writeCount += len - off;
			if (timeseek > 0 && timeend == 0) {
				int packetLength = 6; // minimum to get packet size
				while (packetpos + packetLength < writeCount && buffer !is null) {
					int packetposMB = cast(int) (packetpos % maxMemorySize);
					int streamPos = 0;
					if (buffer[modulo(packetposMB, buffer.length)] == 71) {// TS
						packetLength = 188;
						streamPos = 4;

						// adaptation field
						if ((buffer[modulo(packetposMB + 3, buffer.length)] & 0x20) == 0x20) {
							streamPos += 1 + ((buffer[modulo(packetposMB + 4, buffer.length)] + 256) % 256);
						}

						if (streamPos == 188) {
							streamPos = -1;
						}

					} else if (buffer[modulo(packetposMB + 3, buffer.length)] == -70) { // BA
						packetLength = 14;
						streamPos = -1;
					} else {
						packetLength = 6 + (((buffer[modulo(packetposMB + 4, buffer.length)] + 256) % 256)) * 256 + ((buffer[modulo(packetposMB + 5, buffer.length)] + 256) % 256);
					}
					if (streamPos != -1) {
						mb = packetposMB + streamPos + 18;
						if (!shiftVideo(mb, true)) {
							mb = mb - 5;
							shiftAudio(mb, true);
						}
					}
					packetpos += packetLength;
				}
			}
		}
	}

	
	/**
	 * Determine a modulo value that is guaranteed to be zero or positive, as opposed to
	 * the standard Java % operator which can return a negative value. 
	 * 
	 * @param number Number to divide
	 * @param divisor Number that is used to divide
	 * @return The rest value of the division.
	 */
	private int modulo(int number, int divisor) {
		if (number >= 0) {
			return number % divisor;
		}
		return ((number % divisor) + divisor) % divisor;
	}

	
	override
	public void write(int b) {
		bool bb = b % 100000 == 0;
		WaitBufferedInputStream input = getCurrentInputStream();
		while (bb && ((input !is null && (writeCount - input.getReadCount() > bufferOverflowWarning)) || (input is null && writeCount == bufferOverflowWarning))) {
			try {
				Thread.sleep(CHECK_INTERVAL);
				//LOGGER.trace("BufferedOutputFile Full");
			} catch (InterruptedException e) {
			}
			input = getCurrentInputStream();
		}
		int mb = cast(int) (writeCount++ % maxMemorySize);
		if (buffer !is null) {
			buffer[mb] = cast(byte) b;
			buffered = true;
			if (writeCount == INITIAL_BUFFER_SIZE) {
				buffer = growBuffer(buffer, maxMemorySize);
			}

			if (timeseek > 0 && writeCount > 19) {
				shiftByTimeSeek(mb, mb <= 20);
			}

			// Ditlew - WDTV Live - update any SCR headers
			if (timeseek > 0 && writeCount > 10) {
				shiftSCRByTimeSeek(mb, cast(int) timeseek);
			}
		}
	}

	// Ditlew - Modify SCR
	private void shiftSCRByTimeSeek(int buffer_index, int offset_sec) {
		int m9 = modulo(buffer_index - 9, buffer.length);
		int m8 = modulo(buffer_index - 8, buffer.length);
		int m7 = modulo(buffer_index - 7, buffer.length);
		int m6 = modulo(buffer_index - 6, buffer.length);
		int m5 = modulo(buffer_index - 5, buffer.length);
		int m4 = modulo(buffer_index - 4, buffer.length);
		int m3 = modulo(buffer_index - 3, buffer.length);
		int m2 = modulo(buffer_index - 2, buffer.length);
		int m1 = modulo(buffer_index - 1, buffer.length);
		int m0 = modulo(buffer_index, buffer.length);

		// SCR
		if (buffer[m9] == 0
			&& buffer[m8] == 0
			&& buffer[m7] == 1
			&& buffer[m6] == -70 && // 0xBA - Java/PMS wants -70
			// control bits
			!((buffer[m5] & 128) == 128)
			&& ((buffer[m5] & 64) == 64)
			&& ((buffer[m5] & 4) == 4)
			&& ((buffer[m3] & 4) == 4)
			&& ((buffer[m1] & 4) == 4)
			&& ((buffer[m0] & 1) == 1)) {
			long scr_32_30 = ((buffer[m5] & 56) >> 3);
			long scr_29_15 = ((buffer[m5] & 3) << 13) + (buffer[m4] << 5) + ((buffer[m3] & 248) >> 3);
			long scr_14_00 = ((buffer[m3] & 3) << 13) + (buffer[m2] << 5) + ((buffer[m1] & 248) >> 3);

			long scr = (scr_32_30 << 30) + (scr_29_15 << 15) + scr_14_00;
			long scr_new = scr + (90000L * offset_sec);

			long scr_32_30_new = (scr_new & 7516192768L) >> 30;  // 111000000000000000000000000000000
			long scr_29_15_new = (scr_new & 1073709056L) >> 15;  // 000111111111111111000000000000000
			long scr_14_00_new = (scr_new & 32767L);             // 000000000000000000111111111111111

			// scr_32_30_new
			buffer[m5] = cast(byte) ((buffer[m5] & 199) + ((scr_32_30_new << 3) & 56)); // 11000111

			// scr_29_15_new
			buffer[m5] = cast(byte) ((buffer[m5] & 252) + ((scr_29_15_new >> 13) & 3)); // 00000011
			buffer[m4] = cast(byte) (scr_29_15_new >> 5);                               // 11111111
			buffer[m3] = cast(byte) ((buffer[m3] & 7) + ((scr_29_15_new << 3) & 248));  // 11111000

			// scr_14_00_new
			buffer[m3] = cast(byte) ((buffer[m3] & 252) + ((scr_14_00_new >> 13) & 3)); // 00000011
			buffer[m2] = cast(byte) (scr_14_00_new >> 5);                               // 11111111
			buffer[m1] = cast(byte) ((buffer[m1] & 7) + ((scr_14_00_new << 3) & 248));  // 11111000

			// Debug
			//LOGGER.trace("Ditlew - SCR "+scr+" ("+(int)(scr/90000)+") -> "+scr_new+" ("+(int)(scr_new/90000)+")  "+offset_sec+" secs");
		}
	}

	// Ditlew - Modify GOP
	private void shiftGOPByTimeSeek(int buffer_index, int offset_sec) {
		int m7 = modulo(buffer_index - 7, buffer.length);
		int m6 = modulo(buffer_index - 6, buffer.length);
		int m5 = modulo(buffer_index - 5, buffer.length);
		int m4 = modulo(buffer_index - 4, buffer.length);
		int m3 = modulo(buffer_index - 3, buffer.length);
		int m2 = modulo(buffer_index - 2, buffer.length);
		int m1 = modulo(buffer_index - 1, buffer.length);
		int m0 = modulo(buffer_index, buffer.length);

		// check if valid gop
		if (buffer[m7] == 0
			&& buffer[m6] == 0
			&& buffer[m5] == 1
			&& buffer[m4] == -72 && // 0xB8 - Java/PMS wants -72
			// control bits
			((buffer[m2] & 0x08) == 0x08)
			&& ((buffer[m0] & 31) == 0)
			&& // of interest
			!((buffer[m3] & 128) == 128) && // not drop frm
			!((buffer[m0] & 16) == 16) // not broken
			) {
			// org timecode
			byte h = cast(byte) ((buffer[m3] & 124) >> 2);
			byte m = cast(byte) (((buffer[m3] & 3) << 4) + ((buffer[m2] & 240) >> 4));
			byte s = cast(byte) (((buffer[m2] & 7) << 3) + ((buffer[m1] & 224) >> 5));

			// updated offset
			int _offset = s + m * 60 + h * 60 + offset_sec;

			// new timecode
			byte _h = cast(byte) ((_offset / 3600) % 24);
			byte _m = cast(byte) ((_offset / 60) % 60);
			byte _s = cast(byte) (_offset % 60);

			// update gop
			// h - ok
			buffer[m3] = cast(byte) ((buffer[m3] & 131) + (_h << 2)); // 10000011
			// m - ok
			buffer[m3] = cast(byte) ((buffer[m3] & 252) + (_m >> 4)); // 11111100
			buffer[m2] = cast(byte) ((buffer[m2] & 15) + (_m << 4)); // 00001111
			// s - ok
			buffer[m2] = cast(byte) ((buffer[m2] & 248) + (_s >> 3)); // 11111000
			buffer[m1] = cast(byte) ((buffer[m1] & 31) + (_s << 5)); // 00011111

			// Debug
			//LOGGER.trace("Ditlew - GOP "+h+":"+m+":"+s+" -> "+_h+":"+_m+":"+_s+"  "+offset_sec+" secs");
		}
	}

	private void shiftByTimeSeek(int mb, bool mod) {
		shiftVideo(mb, mod);
		shiftAudio(mb, mod);
	}

	private bool shiftAudio(int mb, bool mod) {
		bool bb = (!mod && (buffer[mb - 10] == -67 || buffer[mb - 10] == -64) && buffer[mb - 11] == 1 && buffer[mb - 12] == 0 && buffer[mb - 13] == 0 && /*(buffer[mb-7]&128)==128 &&*/ (buffer[mb - 6] & 128) == 128/*buffer[mb-6] == -128*/)
			|| (mod && (buffer[modulo(mb - 10, buffer.length)] == -67 || buffer[modulo(mb - 10, buffer.length)] == -64) && buffer[modulo(mb - 11, buffer.length)] == 1 && buffer[modulo(mb - 12, buffer.length)] == 0 && buffer[modulo(mb - 13, buffer.length)] == 0 && /*(buffer[modulo(mb-7)]&128)==128 && */ (buffer[modulo(mb - 6, buffer.length)] & 128) == 128/*buffer[modulo(mb-6, buffer.length)] == -128*/);
		if (bb) {
			int pts = (((((buffer[modulo(mb - 3, buffer.length)] & 0xff) << 8) + (buffer[modulo(mb - 2, buffer.length)] & 0xff)) >> 1) << 15) + ((((buffer[modulo(mb - 1, buffer.length)] & 0xff) << 8) + (buffer[modulo(mb, buffer.length)] & 0xff)) >> 1);
			pts += cast(int) (timeseek * 90000);

			setTS(pts, mb, mod);
			return true;
		}
		return false;
	}

	private bool shiftVideo(int mb, bool mod) {
		bool bb = (!mod
			&& (buffer[mb - 15] == -32 || buffer[mb - 15] == -3)
			&& buffer[mb - 16] == 1
			&& buffer[mb - 17] == 0
			&& buffer[mb - 18] == 0
			&& (buffer[mb - 11] & 128) == 128
			&& (buffer[mb - 9] & 32) == 32) || (mod
			&& (buffer[modulo(mb - 15, buffer.length)] == -32 || buffer[modulo(mb - 15, buffer.length)] == -3)
			&& buffer[modulo(mb - 16, buffer.length)] == 1
			&& buffer[modulo(mb - 17, buffer.length)] == 0
			&& buffer[modulo(mb - 18, buffer.length)] == 0
			&& (buffer[modulo(mb - 11, buffer.length)] & 128) == 128
			&& (buffer[modulo(mb - 9, buffer.length)] & 32) == 32);

		if (bb) { // check EO or FD (tsmuxer)
			int pts = getTS(mb - 5, mod);
			int dts = 0;
			bool dts_present = (buffer[modulo(mb - 11, buffer.length)] & 64) == 64;
			if (dts_present) {
				if ((buffer[modulo(mb - 4, buffer.length)] & 15) == 15) {
					dts = (((((255 - (buffer[modulo(mb - 3, buffer.length)] & 0xff)) << 8) + (255 - (buffer[modulo(mb - 2, buffer.length)] & 0xff))) >> 1) << 15) + ((((255 - (buffer[modulo(mb - 1, buffer.length)] & 0xff)) << 8) + (255 - (buffer[modulo(mb, buffer.length)] & 0xff))) >> 1);
					dts = -dts;
				} else {
					dts = getTS(mb, mod);
				}
			}

			int ts = cast(int) (timeseek * 90000);
			if (mb == 50 && writeCount < maxMemorySize) {
				dts--;
			}
			pts += ts;

			setTS(pts, mb - 5, mod);
			if (dts_present) {
				if (dts < 0) {
					buffer[modulo(mb - 4, buffer.length)] = 17;
				}
				dts += ts;
				setTS(dts, mb, mod);
			}
			return true;
		}
		return false;
	}

	private int getTS(int mb, bool modulo) {
		int m3 = mb - 3;
		int m2 = mb - 2;
		int m1 = mb - 1;
		int m0 = mb;
		if (modulo) {
			m3 = modulo(m3, buffer.length);
			m2 = modulo(m2, buffer.length);
			m1 = modulo(m1, buffer.length);
			m0 = modulo(m0, buffer.length);
		}

		return (((((buffer[m3] & 0xff) << 8) + (buffer[m2] & 0xff)) >> 1) << 15)
			+ ((((buffer[m1] & 0xff) << 8) + (buffer[m0] & 0xff)) >> 1);
	}

	private void setTS(int ts, int mb, bool modulo) {
		int m3 = mb - 3;
		int m2 = mb - 2;
		int m1 = mb - 1;
		int m0 = mb;
		if (modulo) {
			m3 = modulo(m3, buffer.length);
			m2 = modulo(m2, buffer.length);
			m1 = modulo(m1, buffer.length);
			m0 = modulo(m0, buffer.length);
		}
		int pts_low = ts & 32767;
		int pts_high = (ts >> 15) & 32767;
		int pts_left_low = 1 + (pts_low << 1);
		int pts_left_high = 1 + (pts_high << 1);
		buffer[m3] = cast(byte) ((pts_left_high & 65280) >> 8);
		buffer[m2] = cast(byte) (pts_left_high & 255);
		buffer[m1] = cast(byte) ((pts_left_low & 65280) >> 8);
		buffer[m0] = cast(byte) (pts_left_low & 255);
	}

	override
	public int read(bool firstRead, long readCount, byte buf[], int off, int len) {
		if (readCount > INITIAL_BUFFER_SIZE && readCount < maxMemorySize) {
			int newMargin = maxMemorySize - MARGIN_MEDIUM;
			if (bufferOverflowWarning != newMargin) {
				LOGGER._debug("Setting margin to 2Mb");
			}
			this.bufferOverflowWarning = newMargin;
		}
		if (eof && readCount >= writeCount) {
			return -1;
		}
		int c = 0;
		int minBufferS = firstRead ? minMemorySize : secondread_minsize;
		while (writeCount - readCount <= minBufferS && !eof && c < 15) {
			if (c == 0) {
				LOGGER.trace("Suspend Read: readCount=" ~ readCount ~ " / writeCount=" ~ writeCount);
			}
			c++;
			try {
				Thread.sleep(CHECK_INTERVAL);
			} catch (InterruptedException e) {
			}
		}
		if (attachedThread !is null) {
			attachedThread.setReadyToStop(false);
		}
		if (c > 0) {
			LOGGER.trace("Resume Read: readCount=" ~ readCount ~ " / writeCount=" ~ writeCount);
		}

		if (buffer is null || !buffered) {
			return -1;
		}

		int mb = cast(int) (readCount % maxMemorySize);
		int endOF = buffer.length;
		int cut = 0;
		if (eof && (writeCount - readCount) < len) {
			cut = cast(int) (len - (writeCount - readCount));
		}

		if (mb >= endOF - len) {
			System.arraycopy(buffer, mb, buf, off, endOF - mb - cut);
			return endOF - mb;
		} else {
			System.arraycopy(buffer, mb, buf, off, len - cut);
			return len;
		}
	}

	override
	public int read(bool firstRead, long readCount) {
		if (readCount > INITIAL_BUFFER_SIZE && readCount < maxMemorySize) {
			int newMargin = maxMemorySize - MARGIN_MEDIUM;
			if (bufferOverflowWarning != newMargin) {
				LOGGER._debug("Setting margin to 2Mb");
			}
			this.bufferOverflowWarning = newMargin;
		}
		if (eof && readCount >= writeCount) {
			return -1;
		}
		int c = 0;
		int minBufferS = firstRead ? minMemorySize : secondread_minsize;
		while (writeCount - readCount <= minBufferS && !eof && c < 15) {
			if (c == 0) {
				LOGGER.trace("Suspend Read: readCount=" ~ readCount ~ " / writeCount=" ~ writeCount);
			}
			c++;
			try {
				Thread.sleep(CHECK_INTERVAL);
			} catch (InterruptedException e) {
			}
		}
		if (attachedThread !is null) {
			attachedThread.setReadyToStop(false);
		}

		if (c > 0) {
			LOGGER.trace("Resume Read: readCount=" ~ readCount ~ " / writeCount=" ~ writeCount);
		}

		if (buffer is null || !buffered) {
			return -1;
		}
		return 0xff & buffer[cast(int) (readCount % maxMemorySize)];
	}

	override
	public void attachThread(ProcessWrapper thread) {
		if (attachedThread !is null) {
			throw new RuntimeException("BufferedOutputFile is already attached to a Thread: " ~ attachedThread);
		}
		LOGGER._debug("Attaching thread: " ~ thread);
		attachedThread = thread;
	}

	override
	public void removeInputStream(WaitBufferedInputStream inputStream) {
		inputStreams.remove(inputStream);
	}
	
	override
	public void detachInputStream() {
		PMS.get().getFrame().setReadValue(0, "");
		if (attachedThread !is null) {
			attachedThread.setReadyToStop(true);
		}
		Runnable checkEnd = dgRunnable( {
				try {
					Thread.sleep(CHECK_END_OF_PROCESS);
				} catch (InterruptedException e) {
					LOGGER.error(null, e);
				}
				if (attachedThread !is null && attachedThread.isReadyToStop()) {
					if (!attachedThread.isDestroyed()) {
						attachedThread.stopProcess();
					}
					reset();
				}
		});
		(new Thread(checkEnd, "Buffered IO End Checker")).start();
	}

	override
	public synchronized void reset() {
		if (debugOutput !is null) {
			try {
				debugOutput.close();
			} catch (IOException e) {
				LOGGER._debug("Caught exception", e);
			}
		}
		timer.cancel();
		if (buffer !is null) {
			LOGGER.trace("Destroying buffer");
			buffer = null;
		}
		buffered = false;
		if (maxMemorySize != 1048576) {
			PMS.get().getFrame().setValue(0, "Empty");
		}
	}
}
