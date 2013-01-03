module org.serviio.licensing.LicenseProperties;

public enum LicenseProperties
{
  TYPE {
	override
	public String getName()
	{
		return "type";
	}
}, 

  EDITION {
	override
	public String getName()
	{
		return "edition";
	}
}, 

  VERSION {
	override
	public String getName()
	{
		return "version";
	}
}, 

  ID {
	override
	public String getName()
	{
		return "id";
	}
}, 

  NAME {
	override
	public String getName()
	{
		return "name";
	}
}, 

  EMAIL {
	override
	public String getName()
	{
		return "email";
	}
};

  public abstract String getName();
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.licensing.LicenseProperties
 * JD-Core Version:    0.6.2
 */