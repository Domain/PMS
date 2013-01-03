module net.pms.util.PCMAudioOutputStream;

import java.lang.exceptions;
import java.io.OutputStream;

public class PCMAudioOutputStream : FlowParserOutputStream {
	protected int nbchannels;
	protected int sampleFrequency;
	protected int bitsperSample;
	protected int blocksize;
	protected byte[] payload;

	public this(OutputStream source, int nbchannels, int sampleFrequency, int bitsperSample) {
		super(source, 600000);
		this.nbchannels = nbchannels;
		this.sampleFrequency = sampleFrequency;
		this.bitsperSample = bitsperSample;
		swapOrderBits = 2; // swap endian
		init();
	}

	protected void init() {
		blocksize = (2 * ((nbchannels + 1) / 2)) * sampleFrequency * bitsperSample / 1600;
		payload = new byte[4];
		switch (nbchannels) {
			case 1:
				payload[2] = 17;
				break;
			case 2:
				payload[2] = 49;
				break;
			case 3:
				payload[2] = 65;
				break;
			case 4:
				payload[2] = 113;
				break;
			case 5:
				payload[2] = -127;
				break;
			case 6:
				payload[2] = -111;
				break;
			case 7:
				payload[2] = -95;
				break;
			case 8:
				payload[2] = -79;
				break;
		}
		payload[0] = cast(byte) ((blocksize >> 8) & 0xff);
		payload[1] = cast(byte) ((blocksize + 256) % 256);
		if (sampleFrequency == 96000) {
			payload[2] = cast(byte) (payload[2] + 3);
		}
		if (sampleFrequency == 192000) {
			payload[2] = cast(byte) (payload[2] + 4);
		}
		payload[3] = cast(byte) (16 * (bitsperSample - 12));
	}

	override
	protected void afterChunkSend() {
	}

	override
	protected void analyzeBuffer(byte[] data, int off, int len) {
		streamableByteNumber = blocksize;
	}

	override
	protected void beforeChunkSend() {
		writePayload(payload);
	}
}
