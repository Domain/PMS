module org.serviio.dlna.H264Profile;

public enum H264Profile
{
  BASELINE {
	override
	public int getCode()
	{
		return 66;
	}
}, 

  MAIN {
	override
	public int getCode()
	{
		return 77;
	}
}, 

  EXTENDED {
	override
	public int getCode()
	{
		return 88;
	}
}, 

  HIGH {
	override
	public int getCode()
	{
		return 100;
	}
}, 

  HIGH_10 {
	override
	public int getCode()
	{
		return 110;
	}
}, 

  HIGH_422 {
	override
	public int getCode()
	{
		return 122;
	}
}, 

  HIGH_444 {
	override
	public int getCode()
	{
		return 244;
	}
};

  public abstract int getCode();

  public static H264Profile getByCode(int code)
  {
    for (H264Profile p : values()) {
      if (p.getCode() == code) {
        return p;
      }
    }
    return null;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.dlna.H264Profile
 * JD-Core Version:    0.6.2
 */