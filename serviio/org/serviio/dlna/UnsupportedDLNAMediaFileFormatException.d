module org.serviio.dlna.UnsupportedDLNAMediaFileFormatException;

public class UnsupportedDLNAMediaFileFormatException : Exception
{
  private static final long serialVersionUID = -896277702729810672L;

  public this()
  {
  }

  public this(String message, Throwable cause)
  {
    super(message, cause);
  }

  public this(String message)
  {
    super(message);
  }

  public this(Throwable cause)
  {
    super(cause);
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.dlna.UnsupportedDLNAMediaFileFormatException
 * JD-Core Version:    0.6.2
 */