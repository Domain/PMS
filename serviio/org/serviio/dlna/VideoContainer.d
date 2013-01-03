module org.serviio.dlna.VideoContainer;

import org.serviio.util.StringUtils;

public enum VideoContainer
{
  ANY {
	override
	public String getFFmpegValue()
	{
		throw new RuntimeException("Cannot transcode audio into any");
	}
}, 

  AVI {
	override
	public String getFFmpegValue()
	{
		return "avi";
	}
}, 

  MATROSKA {
	override
	public String getFFmpegValue()
	{
		return "matroska";
	}
}, 

  ASF {
	override
	public String getFFmpegValue()
	{
		return "asf";
	}
}, 

  MP4 {
	override
	public String getFFmpegValue()
	{
		return "mp4";
	}
}, 

  MPEG2PS {
	override
	public String getFFmpegValue()
	{
		return "vob";
	}
}, 

  MPEG2TS {
	override
	public String getFFmpegValue()
	{
		return "mpegts";
	}
}, 

  M2TS {
	override
	public String getFFmpegValue()
	{
		return "mpegts";
	}
}, 

  MPEG1 {
	override
	public String getFFmpegValue()
	{
		return "mpegvideo";
	}
}, 

  FLV {
	override
	public String getFFmpegValue()
	{
		return "flv";
	}
}, 

  WTV {
	override
	public String getFFmpegValue()
	{
		return "wtv";
	}
}, 

  OGG {
	override
	public String getFFmpegValue()
	{
		return "ogg";
	}
}, 

  THREE_GP {
	override
	public String getFFmpegValue()
	{
		return "3gp";
	}
}, 

  RTP {
	override
	public String getFFmpegValue()
	{
		return "rtp";
	}
}, 

  RTSP {
	override
	public String getFFmpegValue()
	{
		return "rtsp";
	}
}, 

  APPLE_HTTP {
	override
	public String getFFmpegValue()
	{
		return "applehttp";
	}
}, 

  REAL_MEDIA {
	override
	public String getFFmpegValue()
	{
		return "rm";
	}
};

  public abstract String getFFmpegValue();

  public static VideoContainer getByFFmpegValue(String ffmpegName, String filePath)
  {
    if (ffmpegName !is null) {
      if (ffmpegName.equals("*"))
        return ANY;
      if (ffmpegName.equals("asf"))
        return ASF;
      if (ffmpegName.equals("mpegvideo"))
        return MPEG1;
      if ((ffmpegName.equals("mpeg")) || (ffmpegName.equals("vob")))
        return MPEG2PS;
      if (ffmpegName.equals("mpegts"))
        return MPEG2TS;
      if (ffmpegName.equals("m2ts"))
        return M2TS;
      if (ffmpegName.equals("matroska"))
        return MATROSKA;
      if (ffmpegName.equals("avi"))
        return AVI;
      if ((ffmpegName.equals("mov")) || (ffmpegName.equals("mp4"))) {
        if ((filePath !is null) && (StringUtils.localeSafeToLowercase(filePath).endsWith(".3gp"))) {
          return THREE_GP;
        }
        return MP4;
      }if (ffmpegName.equals("flv"))
        return FLV;
      if (ffmpegName.equals("wtv"))
        return WTV;
      if (ffmpegName.equals("ogg"))
        return OGG;
      if (ffmpegName.equals("3gp"))
        return THREE_GP;
      if (ffmpegName.equals("rtp"))
        return RTP;
      if (ffmpegName.equals("rtsp"))
        return RTSP;
      if ((ffmpegName.equals("applehttp")) || (ffmpegName.equals("hls")))
        return APPLE_HTTP;
      if (ffmpegName.equals("rm")) {
        return REAL_MEDIA;
      }
    }
    return null;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.dlna.VideoContainer
 * JD-Core Version:    0.6.2
 */