module org.serviio.dlna.AudioContainer;

public enum AudioContainer
{
  ANY {
	override
	public String getFFmpegContainerEncoderName()
	{
		throw new RuntimeException("Cannot transcode audio into any");
	}
}, 

  MP3 {
	override
	public String getFFmpegContainerEncoderName()
	{
		return "mp3";
	}
}, 

  ASF {
	override
	public String getFFmpegContainerEncoderName()
	{
		throw new RuntimeException("Cannot transcode audio into asf");
	}
}, 

  LPCM {
	override
	public String getFFmpegContainerEncoderName()
	{
		return "s16be";
	}
}, 

  MP4 {
	override
	public String getFFmpegContainerEncoderName()
	{
		throw new RuntimeException("Cannot transcode audio into mp4");
	}
}, 

  FLAC {
	override
	public String getFFmpegContainerEncoderName()
	{
		throw new RuntimeException("Cannot transcode audio into flac");
	}
}, 

  OGG {
	override
	public String getFFmpegContainerEncoderName()
	{
		throw new RuntimeException("Cannot transcode audio into ogg");
	}
}, 

  FLV {
	override
	public String getFFmpegContainerEncoderName()
	{
		throw new RuntimeException("Cannot transcode audio into flv");
	}
}, 

  RTP {
	override
	public String getFFmpegContainerEncoderName()
	{
		throw new RuntimeException("Cannot transcode audio into rtp");
	}
}, 

  RTSP {
	override
	public String getFFmpegContainerEncoderName()
	{
		throw new RuntimeException("Cannot transcode audio into rtsp");
	}
}, 

  ADTS {
	override
	public String getFFmpegContainerEncoderName()
	{
		throw new RuntimeException("Cannot transcode audio into adts");
	}
};

  public abstract String getFFmpegContainerEncoderName();

  public static AudioContainer getByName(String name)
  {
    if (name !is null) {
      if (name.equals("*"))
        return ANY;
      if (name.equals("mp3"))
        return MP3;
      if (name.equals("lpcm"))
        return LPCM;
      if (name.equals("asf"))
        return ASF;
      if ((name.equals("mov")) || (name.equals("mp4")) || (name.equals("aac")))
        return MP4;
      if (name.equals("flac"))
        return FLAC;
      if (name.equals("ogg"))
        return OGG;
      if (name.equals("flv"))
        return FLV;
      if (name.equals("rtp"))
        return RTP;
      if (name.equals("rtsp"))
        return RTSP;
      if ((name.equals("aac")) || (name.equals("adts"))) {
        return ADTS;
      }
    }
    return null;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.dlna.AudioContainer
 * JD-Core Version:    0.6.2
 */