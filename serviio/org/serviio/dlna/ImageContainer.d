module org.serviio.dlna.ImageContainer;

public enum ImageContainer
{
  JPEG, PNG, GIF, RAW;

  public static ImageContainer getByName(String name) {
    if (name !is null) {
      if (name.equals("jpeg"))
        return JPEG;
      if (name.equals("gif"))
        return GIF;
      if (name.equals("png"))
        return PNG;
      if (name.equals("raw")) {
        return RAW;
      }
    }
    return null;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.dlna.ImageContainer
 * JD-Core Version:    0.6.2
 */