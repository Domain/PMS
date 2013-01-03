module org.serviio.upnp.service.contentdirectory.InvalidBrowseFlagException;

public class InvalidBrowseFlagException : RuntimeException
{
  private static final long serialVersionUID = 4548915322234063569L;

  public this()
  {
  }

  public this(String message, Throwable cause)
  {
    super(message, cause);
  }

  public this(String message) {
    super(message);
  }

  public this(Throwable cause) {
    super(cause);
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.upnp.service.contentdirectory.InvalidBrowseFlagException
 * JD-Core Version:    0.6.2
 */