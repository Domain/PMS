module net.pms.util.H264AnnexBInputStream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.exceptions;
import java.io.InputStream;

public class H264AnnexBInputStream : InputStream {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!H264AnnexBInputStream();
	private InputStream source;
	private int nextTarget;
	private bool firstHeader;
	private byte[] header;
	//private int remaining;

	public this(InputStream source, byte[] header) {
		this.source = source;
		this.header = header;
		firstHeader = true;
		nextTarget = -1;
	}

	override
	public int read() {
		return -1;
	}

	override
	public int read(byte[] b, int off, int len) {
		byte[] h = null;
		bool insertHeader = false;

		if (nextTarget == -1) {
			h = getArray(4);
			if (h is null) {
				return -1;
			}
			nextTarget = 65536 * 256 * (h[0] & 0xff) + 65536 * (h[1] & 0xff) + 256 * (h[2] & 0xff) + (h[3] & 0xff);
			h = getArray(3);
			if (h is null) {
				return -1;
			}
			insertHeader = ((h[0] & 37) == 37 && (h[1] & -120) == -120);
			if (!insertHeader) {
				System.arraycopy(cast(byte[])[0, 0, 0, 1], 0, b, off, 4);
				off += 4;

			}
			nextTarget = nextTarget - 3;
		}

		if (nextTarget == -1) {
			return -1;
		}

		if (insertHeader) {
			byte[] defHeader = header;
			if (!firstHeader) {
				defHeader = new byte[header.length + 1];
				System.arraycopy(header, 0, defHeader, 0, header.length);
				defHeader[defHeader.length - 1] = 1;
				defHeader[defHeader.length - 2] = 0;
			}
			if (defHeader.length < (len - off)) {
				System.arraycopy(defHeader, 0, b, off, defHeader.length);
				off += defHeader.length;
			} else {
				System.arraycopy(defHeader, 0, b, off, (len - off));
				off = len;
			}
			//logger.info("header inserted / nextTarget: " + nextTarget);
			firstHeader = false;
		}

		if (h !is null) {
			System.arraycopy(h, 0, b, off, 3);
			off += 3;
			//logger.info("frame start inserted");
		}

		if (nextTarget < (len - off)) {

			h = getArray(nextTarget);
			if (h is null) {
				return -1;
			}
			System.arraycopy(h, 0, b, off, nextTarget);
			//logger.info("Frame copied: " + nextTarget);
			off += nextTarget;

			nextTarget = -1;

		} else {

			h = getArray(len - off);
			if (h is null) {
				return -1;
			}
			System.arraycopy(h, 0, b, off, (len - off));
			//logger.info("Frame copied: " + (len - off));
			nextTarget = nextTarget - (len - off);
			off = len;

		}

		return off;
	}

	private byte[] getArray(int length) {
		if (length < 0) {
			logger.trace("Negative array ?");
			return null;
		}
		byte[] bb = new byte[length];
		int n = source.read(bb);
		if (n == -1) {
			return null;
		}
		while (n < length) {
			int u = source.read(bb, n, length - n);
			if (u == -1) {
				break;
			}
			n += u;
		}
		return bb;
	}

	override
	public void close() {
		super.close();
		if (source !is null) {
			source.close();
		}
	}
}
