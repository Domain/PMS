module org.serviio.dlna.VideoCodec;

public enum VideoCodec
{
  H264 {
	override
	public String getFFmpegEncoderName()
	{
		throw new RuntimeException("Canot transcode to H264");
	}
}, 

  H263 {
	override
	public String getFFmpegEncoderName()
	{
		throw new RuntimeException("Canot transcode to H263");
	}
}, 

  VC1 {
	override
	public String getFFmpegEncoderName()
	{
		throw new RuntimeException("Canot transcode to VC1");
	}
}, 

  MPEG4 {
	override
	public String getFFmpegEncoderName()
	{
		throw new RuntimeException("Canot transcode to MPEG4");
	}
}, 

  MSMPEG4 {
	override
	public String getFFmpegEncoderName()
	{
		throw new RuntimeException("Canot transcode to MSMPEG4");
	}
}, 

  MPEG2 {
	override
	public String getFFmpegEncoderName()
	{
		return "mpeg2video";
	}
}, 

  WMV {
	override
	public String getFFmpegEncoderName()
	{
		return "wmv2";
	}
}, 

  MPEG1 {
	override
	public String getFFmpegEncoderName()
	{
		throw new RuntimeException("Canot transcode to Mpeg1");
	}
}, 

  MJPEG {
	override
	public String getFFmpegEncoderName()
	{
		throw new RuntimeException("Canot transcode to MJpeg");
	}
}, 

  FLV {
	override
	public String getFFmpegEncoderName()
	{
		return "flv";
	}
}, 

  VP6 {
	override
	public String getFFmpegEncoderName()
	{
		throw new RuntimeException("Canot transcode to VP6");
	}
}, 

  VP8 {
	override
	public String getFFmpegEncoderName()
	{
		throw new RuntimeException("Canot transcode to VP8");
	}
}, 

  THEORA {
	override
	public String getFFmpegEncoderName()
	{
		throw new RuntimeException("Canot transcode to Theora");
	}
}, 

  DV {
	override
	public String getFFmpegEncoderName()
	{
		throw new RuntimeException("Canot transcode to DV");
	}
}, 

  REAL {
	override
	public String getFFmpegEncoderName()
	{
		throw new RuntimeException("Canot transcode to Real Video");
	}
};

  public abstract String getFFmpegEncoderName();

  public static VideoCodec getByFFmpegValue(String ffmpegName)
  {
    if (ffmpegName !is null) {
      if (ffmpegName.equals("vc1"))
        return VC1;
      if (ffmpegName.equals("mpeg4"))
        return MPEG4;
      if (ffmpegName.startsWith("msmpeg4"))
        return MSMPEG4;
      if (ffmpegName.equals("mpeg2video"))
        return MPEG2;
      if (ffmpegName.equals("h264"))
        return H264;
      if ((ffmpegName.equals("wmv1")) || (ffmpegName.equals("wmv3")) || (ffmpegName.equals("wmv2")))
        return WMV;
      if ((ffmpegName.equals("mpeg1video")) || (ffmpegName.equals("mpegvideo")))
        return MPEG1;
      if ((ffmpegName.equals("mjpeg")) || (ffmpegName.equals("mjpegb")))
        return MJPEG;
      if (ffmpegName.startsWith("vp6"))
        return VP6;
      if (ffmpegName.startsWith("vp8"))
        return VP8;
      if (ffmpegName.startsWith("flv"))
        return FLV;
      if (ffmpegName.equals("theora"))
        return THEORA;
      if (ffmpegName.equals("dvvideo"))
        return DV;
      if (ffmpegName.startsWith("h263"))
        return H263;
      if (ffmpegName.startsWith("rv")) {
        return REAL;
      }
    }
    return null;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.dlna.VideoCodec
 * JD-Core Version:    0.6.2
 */