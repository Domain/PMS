module com.sun.jna.Platform;

public class Platform {
	public static bool isWindows()
	{
		version(Windows)
			return true;
		else
			return false;
	}

	public static bool isMac()
	{
		version(OSX)
			return true;
		else
			return false;
	}

	public static bool isLinux()
	{
		version(linux)
			return true;
		else
			return false;
	}
}