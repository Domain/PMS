module net.pms.util.PMSUtil;

import net.pms.PMS;
import net.pms.newgui.LooksFrame;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Arrays;

public class PMSUtil {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!PMSUtil();

	deprecated
	public static T[] copyOf(T)(T[] original, int newLength) {
		logger.info("deprecated PMSUtil.copyOf called");
		return Arrays.copyOf(original, newLength);
	}

	/**
	 * Open HTTP URLs in the default browser.
	 * @param uri URI string to open externally.
	 * @deprecated call SystemUtils.browseURI
	 */
	deprecated
	public static void browseURI(String uri) {
		logger.info("deprecated PMSUtil.browseURI called");
		PMS.get().getRegistry().browseURI(uri);
	}

	deprecated
	public static void addSystemTray(immutable LooksFrame frame) {
		logger.info("deprecated PMSUtil.addSystemTray called");
		PMS.get().getRegistry().addSystemTray(frame);
	}

	deprecated
	public static bool isNetworkInterfaceLoopback(NetworkInterface ni) {
		logger.info("deprecated PMSUtil.isNetworkInterfaceLoopback called");
		return PMS.get().getRegistry().isNetworkInterfaceLoopback(ni);
	}

	/**
	 * Fetch the hardware address for a network interface.
	 * 
	 * @param ni Interface to fetch the mac address for
	 * @return the mac address as bytes, or null if it couldn't be fetched.
	 * @throws SocketException
	 *             This won't happen on Mac OS, since the NetworkInterface is
	 *             only used to get a name.
	 */
	deprecated
	public static byte[] getHardwareAddress(NetworkInterface ni) {
		logger.info("deprecated PMSUtil.getHardwareAddress called");
		return PMS.get().getRegistry().getHardwareAddress(ni);
	}
}
