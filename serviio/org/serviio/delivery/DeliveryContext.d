module org.serviio.delivery.DeliveryContext;

public class DeliveryContext
{
  public static final DeliveryContext LOCAL = new DeliveryContext(true, null);
  private bool localContent;
  private String userAgent;

  public this(bool localContent, String userAgent)
  {
    this.localContent = localContent;
    this.userAgent = userAgent;
  }

  public bool isLocalContent() {
    return localContent;
  }

  public String getUserAgent() {
    return userAgent;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.delivery.DeliveryContext
 * JD-Core Version:    0.6.2
 */