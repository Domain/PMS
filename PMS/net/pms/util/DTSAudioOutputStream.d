module net.pms.util.DTSAudioOutputStream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.exceptions;
import java.io.OutputStream;

public class DTSAudioOutputStream : FlowParserOutputStream {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!DTSAudioOutputStream();
	private static int[] bits = [16, 16, 20, 20, 0, 24, 24];
	private bool dts = false;
	private bool dtsHD = false;
	private int framesize;
	private OutputStream _out;
	private int padding;

	public this(OutputStream _out) {
		super(_out, 600000);
		if (cast(PCMAudioOutputStream)_out !is null) {
			PCMAudioOutputStream pout = cast(PCMAudioOutputStream) _out;
			pout.swapOrderBits = 0;
		}
		this._out = _out;
		neededByteNumber = 15;
	}

	override
	protected void afterChunkSend() {
		padWithZeros(padding);
	}

	override
	protected void analyzeBuffer(byte[] data, int off, int len) {
		if (data[off + 0] == 100 && data[off + 1] == 88 && data[off + 2] == 32 && data[off + 3] == 37) {
			dtsHD = true;
			streamableByteNumber = ((data[off + 6] & 0x0f) << 11) + ((data[off + 7] & 0xff) << 3) + ((data[off + 8] & 0xf0) >> 5) + 1;
			discard = true;
		} else if (data[off + 0] == 127 && data[off + 1] == -2 && data[off + 2] == -128 && data[off + 3] == 1) {
			discard = false;
			dts = true;
			streamableByteNumber = framesize;
			if (framesize == 0) {
				framesize = ((data[off + 5] & 0x03) << 12) + ((data[off + 6] & 0xff) << 4) + ((data[off + 7] & 0xf0) >> 4) + 1;
				int bitspersample = ((data[off + 11] & 0x01) << 2) + ((data[off + 12] & 0xfc) >> 6);
				streamableByteNumber = framesize;
				//reset of default values
				int pcm_wrapped_frame_size = 2048;
				if (cast(PCMAudioOutputStream)_out !is null) {
					PCMAudioOutputStream pout = cast(PCMAudioOutputStream) _out;
					pout.nbchannels = 2;
					pout.sampleFrequency = 48000;
					pout.bitsperSample = 16;
					pout.init();
				}
				padding = pcm_wrapped_frame_size - framesize;
				if (bitspersample < 7) {
					logger.trace("DTS bits per sample: " ~ bits[bitspersample].toString());
				}
				logger.trace("DTS framesize: " ~ framesize.toString());
			}
		} else {
			// DTS wrongly extracted ?... searching for start of the frame
			for (int i = 3; i < 2020; i++) {
				if (data.length > i && data[i - 3] == 127 && data[i - 2] == -2 && data[i - 1] == -128 && data[i] == 1) {
					// skip DTS first frame as it's incomplete
					discard = true;
					streamableByteNumber = i - 3;
					break;
				} else if (data.length > i && data[i - 3] == 100 && data[i - 2] == 88 && data[i - 1] == 32 && data[i] == 37) {
					// skip DTS-HD first frame
					discard = true;
					streamableByteNumber = i - 3;
					break;
				}
			}
		}
	}

	override
	protected void beforeChunkSend() {
	}

	public bool isDts() {
		return dts;
	}

	public bool isDtsHD() {
		return dtsHD;
	}
}
