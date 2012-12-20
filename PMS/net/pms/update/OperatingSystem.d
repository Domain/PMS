module net.pms.update.OperatingSystem;

public class OperatingSystem {
	private static immutable String platformName = detectPlatform();

	private static String detectPlatform() {
		String fullPlatform = System.getProperty("os.name", "unknown");
		String platform = fullPlatform.split(" ")[0].toLowerCase();
		return platform;
	}

	public String getPlatformName() {
		assert(platformName !is null);
		return platformName;
	}

	override
	public String toString() {
		return getPlatformName();
	}

	public bool isWindows() {
		return getPlatformName().equals("windows");
	}
}
