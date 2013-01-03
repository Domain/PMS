module org.serviio.dlna.AudioCodec;

public enum AudioCodec
{
  MP3 {
	override
	public String getFFmpegEncoderName()
	{
		return "libmp3lame";
	}
}, 

  MP2 {
	override
	public String getFFmpegEncoderName()
	{
		return "mp2";
	}
}, 

  MP1 {
	override
	public String getFFmpegEncoderName()
	{
		return "mp1";
	}
}, 

  AAC {
	override
	public String getFFmpegEncoderName()
	{
		return "aac";
	}
}, 

  AC3 {
	override
	public String getFFmpegEncoderName()
	{
		if (System.getProperty("serviio.fixedPointEncoders") is null) {
	      return "ac3";
	    } 
	    return "ac3_fixed";
	}
}, 

  LPCM {
	override
	public String getFFmpegEncoderName()
	{
		return "pcm_s16be";
	}
}, 

  DTS {
	override
	public String getFFmpegEncoderName()
	{
		return "dca";
	}
}, 

  WMA {
	override
	public String getFFmpegEncoderName()
	{
		return "wmav2";
	}
}, 

  WMA_PRO {
	override
	public String getFFmpegEncoderName()
	{
		return "wmapro";
	}
}, 

  FLAC {
	override
	public String getFFmpegEncoderName()
	{
		return "flac";
	}
}, 

  VORBIS {
	override
	public String getFFmpegEncoderName()
	{
		return "vorbis";
	}
}, 

  TRUEHD {
	override
	public String getFFmpegEncoderName()
	{
		return "truehd";
	}
}, 

  AMR {
	override
	public String getFFmpegEncoderName()
	{
		return "amrnb";
	}
}, 

  REAL {
	override
	public String getFFmpegEncoderName()
	{
		throw new RuntimeException("RealAudio is not supported");
	}
};

  public abstract String getFFmpegEncoderName();

  public static AudioCodec getByFFmpegDecoderName(String ffmpegName)
  {
    if (ffmpegName !is null) {
      if (ffmpegName.equals("mp3"))
        return MP3;
      if ((ffmpegName.equals("ac3")) || (ffmpegName.startsWith("ac-3")) || (ffmpegName.equals("liba52")) || (ffmpegName.equals("eac3")))
      {
        return AC3;
      }if ((ffmpegName.equals("aac")) || (ffmpegName.equals("mpeg4aac")) || (ffmpegName.equals("aac_latm")))
        return AAC;
      if ((ffmpegName.startsWith("dca")) || (ffmpegName.startsWith("dts")))
        return DTS;
      if ((ffmpegName.equals("wmav1")) || (ffmpegName.equals("wmav2")))
        return WMA;
      if ((ffmpegName.equals("lpcm")) || (ffmpegName.startsWith("pcm_")) || (ffmpegName.startsWith("adpcm_")))
        return LPCM;
      if ((ffmpegName.equals("wmapro")) || (ffmpegName.equals("0x0162")))
        return WMA_PRO;
      if (ffmpegName.equals("mp2"))
        return MP2;
      if (ffmpegName.equals("mp1"))
        return MP1;
      if (ffmpegName.equals("flac"))
        return FLAC;
      if (ffmpegName.equals("vorbis"))
        return VORBIS;
      if (ffmpegName.equals("truehd"))
        return TRUEHD;
      if ((ffmpegName.equals("amrnb")) || (ffmpegName.equals("amrwb")) || (ffmpegName.equals("amr_nb")) || (ffmpegName.equals("amr_wb")))
        return AMR;
      if ((ffmpegName.equals("ralf")) || (ffmpegName.startsWith("real")) || (ffmpegName.equals("sipr")) || (ffmpegName.equals("cook"))) {
        return REAL;
      }
    }
    return null;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.dlna.AudioCodec
 * JD-Core Version:    0.6.2
 */