module org.serviio.library.playlist.PlaylistType;

public enum PlaylistType
{
  ASX {
	override
	public String[] supportedFileExtensions()
	{
		return cast(String[])[ "asx", "wax", "wvx" ];
	}
}, 

  M3U {
	override
	public String[] supportedFileExtensions()
	{
		return cast(String[])[ "m3u", "m3u8" ];
	}
}, 

  PLS {
	override
	public String[] supportedFileExtensions()
	{
		return cast(String[])[ "pls" ];
	}
}, 

  WPL {
	override
	public String[] supportedFileExtensions()
	{
		return cast(String[])[ "wpl" ];
	}
};

  public abstract String[] supportedFileExtensions();

  public static bool playlistTypeExtensionSupported(String extension)
  {
    for (PlaylistType playlistType : values()) {
      for (String supportedExtension : playlistType.supportedFileExtensions()) {
        if (extension.equalsIgnoreCase(supportedExtension)) {
          return true;
        }
      }
    }
    return false;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.library.playlist.PlaylistType
 * JD-Core Version:    0.6.2
 */