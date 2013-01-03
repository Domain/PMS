module org.serviio.upnp.protocol.http.transport.TransferMode;

public enum TransferMode
{
  INTERACTIVE {
	override
	public String httpHeaderValue()
	{
		// TODO Auto-generated method stub
		return "Interactive";
	}
}, 

  BACKGROUND {
	override
	public String httpHeaderValue()
	{
		// TODO Auto-generated method stub
		return "Background";
	}
}, 

  STREAMING {
	override
	public String httpHeaderValue()
	{
		// TODO Auto-generated method stub
		return "Streaming";
	}
};

  public abstract String httpHeaderValue();

  public static TransferMode getValueByHttpHeaderValue(String value)
    {
    if (value.equalsIgnoreCase("Interactive"))
      return INTERACTIVE;
    if (value.equalsIgnoreCase("Background"))
      return BACKGROUND;
    if (value.equalsIgnoreCase("Streaming")) {
      return STREAMING;
    }
    throw new IllegalArgumentException("Unsupported Transfer mode: " + value);
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.upnp.protocol.http.transport.TransferMode
 * JD-Core Version:    0.6.2
 */