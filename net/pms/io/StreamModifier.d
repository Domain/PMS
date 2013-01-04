module net.pms.io.StreamModifier;

public class StreamModifier {
	private byte header[];
	private bool h264AnnexB;
	private bool pcm;
	private int nbChannels;
	private int sampleFrequency;
	private int bitsPerSample;
	private bool dtsEmbed;

	public byte[] getHeader() {
		return header;
	}

	public void setHeader(byte[] header) {
		this.header = header;
	}

	/**
	 * @deprecated Use {@link #isH264AnnexB()}.
	 */
	deprecated
	public bool isH264_annexb() {
		return isH264AnnexB();
	}

	public bool isH264AnnexB() {
		return h264AnnexB;
	}

	/**
	 * @deprecated Use {@link #setH264AnnexB(bool)}.
	 */
	deprecated
	public void setH264_annexb(bool h264AnnexB) {
		setH264AnnexB(h264AnnexB);
	}

	public void setH264AnnexB(bool h264AnnexB) {
		this.h264AnnexB = h264AnnexB;
	}

	/**
	 * @deprecated Use {@link #isDtsEmbed()}.
	 */
	deprecated
	public bool isDtsembed() {
		return isDtsEmbed();
	}

	public bool isDtsEmbed() {
		return dtsEmbed;
	}

	/**
	 * @deprecated Use {@link #setDtsEmbed(bool)}.
	 */
	deprecated
	public void setDtsembed(bool dtsEmbed) {
		setDtsEmbed(dtsEmbed);
	}

	public void setDtsEmbed(bool dtsEmbed) {
		this.dtsEmbed = dtsEmbed;
	}

	public bool isPcm() {
		return pcm;
	}

	public void setPcm(bool pcm) {
		this.pcm = pcm;
	}

	/**
	 * @deprecated Use {@link #getNbChannels()}.
	 */
	deprecated
	public int getNbchannels() {
		return getNbChannels();
	}

	public int getNbChannels() {
		return nbChannels;
	}

	/**
	 * @deprecated Use {@link #setNbChannels(int)}.
	 */
	deprecated
	public void setNbchannels(int nbChannels) {
		setNbChannels(nbChannels);
	}

	public void setNbChannels(int nbChannels) {
		this.nbChannels = nbChannels;
	}

	public int getSampleFrequency() {
		return sampleFrequency;
	}

	public void setSampleFrequency(int sampleFrequency) {
		this.sampleFrequency = sampleFrequency;
	}

	/**
	 * @deprecated Use {@link #getBitsPerSample()}.
	 */
	deprecated
	public int getBitspersample() {
		return getBitsPerSample();
	}

	public int getBitsPerSample() {
		return bitsPerSample;
	}

	/**
	 * @deprecated Use {@link #setBitsPerSample(int)}.
	 */
	deprecated
	public void setBitspersample(int bitsPerSample) {
		setBitsPerSample(bitsPerSample);
	}

	public void setBitsPerSample(int bitsPerSample) {
		this.bitsPerSample = bitsPerSample;
	}
}
