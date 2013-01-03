module org.serviio.upnp.protocol.soap.InvocationError;

public enum InvocationError
{
  INVALID_ACTION {
	override
	public int getCode()
	{
		// TODO Auto-generated method stub
		return 401;
	}

	override
	public String getDescription()
	{
		// TODO Auto-generated method stub
		return "Invalid Action";
	}
}, 

  INVALID_ARGS {
	override
	public int getCode()
	{
		// TODO Auto-generated method stub
		return 402;
	}

	override
	public String getDescription()
	{
		// TODO Auto-generated method stub
		return "Invalid Args";
	}
}, 

  INVALID_VAR {
	override
	public int getCode()
	{
		// TODO Auto-generated method stub
		return 404;
	}

	override
	public String getDescription()
	{
		// TODO Auto-generated method stub
		return "Invalid Var";
	}
}, 

  ACTION_FAILED {
	override
	public int getCode()
	{
		// TODO Auto-generated method stub
		return 501;
	}

	override
	public String getDescription()
	{
		// TODO Auto-generated method stub
		return "Action Failed";
	}
}, 

  CON_MAN_INVALID_CONNECTION_REFERENCE {
	override
	public int getCode()
	{
		// TODO Auto-generated method stub
		return 706;
	}

	override
	public String getDescription()
	{
		// TODO Auto-generated method stub
		return "Invalid connection reference";
	}
}, 

  CON_MAN_NO_SUCH_OBJECT {
	override
	public int getCode()
	{
		// TODO Auto-generated method stub
		return 701;
	}

	override
	public String getDescription()
	{
		// TODO Auto-generated method stub
		return "No such object";
	}
}, 

  CON_MAN_NO_SUCH_CONTAINER {
	override
	public int getCode()
	{
		// TODO Auto-generated method stub
		return 710;
	}

	override
	public String getDescription()
	{
		// TODO Auto-generated method stub
		return "No such container";
	}
};

  public abstract int getCode();

  public abstract String getDescription();
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.upnp.protocol.soap.InvocationError
 * JD-Core Version:    0.6.2
 */