module org.serviio.library.online.feed.module.gametrailers.GameTrailersExModuleImpl;

import com.sun.syndication.feed.module.ModuleImpl;

public class GameTrailersExModuleImpl : ModuleImpl
  : GameTrailersExModule
{
  private static final long serialVersionUID = -9195315748559355960L;
  private Long fileSize;
  private String thumbnailUrl;

  public this()
  {
    super(GameTrailersExModule.class, "http://www.gametrailers.com/rssexplained.php");
  }

  public void copyFrom(Object obj)
  {
    GameTrailersExModule module = cast(GameTrailersExModule)obj;
    setFileSize(module.getFileSize());
    setThumbnailUrl(module.getThumbnailUrl());
  }

  public Class<?> getInterface()
  {
    return GameTrailersExModule.class;
  }

  public Long getFileSize()
  {
    return fileSize;
  }

  public void setFileSize(Long fileSize)
  {
    this.fileSize = fileSize;
  }

  public String getThumbnailUrl()
  {
    return thumbnailUrl;
  }

  public void setThumbnailUrl(String thumbnailUrl)
  {
    this.thumbnailUrl = thumbnailUrl;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.library.online.feed.module.gametrailers.GameTrailersExModuleImpl
 * JD-Core Version:    0.6.2
 */