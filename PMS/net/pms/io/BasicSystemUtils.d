/*
 * PS3 Media Server, for streaming any medias to your PS3.
 * Copyright (C) 2011 G.Zsombor
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; version 2
 * of the License only.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
module net.pms.io.BasicSystemUtils;

import com.sun.jna.Platform;
import net.pms.Messages;
import net.pms.PMS;
import net.pms.newgui.LooksFrame;
import net.pms.util.PropertiesUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

////import java.awt.*;
//import java.awt.event.ActionEvent;
//import java.awt.event.ActionListener;
import java.io.File;
import java.io.IOException;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.net.URI;
import java.net.URISyntaxException;

/**
 * Base implementation for the SystemUtils class for the generic cases.
 * @author zsombor
 *
 */
public class BasicSystemUtils : SystemUtils {
	private immutable static Logger logger = LoggerFactory.getLogger!BasicSystemUtils(); 

	protected String vlcp;
	protected String vlcv;
	protected bool avis;

	override
	public void disableGoToSleep() {

	}

	override
	public void reenableGoToSleep() {

	}

	override
	public File getAvsPluginsDir() {
		return null;
	}

	override
	public String getShortPathNameW(String longPathName) {
		return longPathName;
	}

	override
	public String getWindowsDirectory() {
		return null;
	}

	override
	public String getDiskLabel(File f) {
		return null;
	}

	override
	public bool isKerioFirewall() {
		return false;
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see net.pms.io.SystemUtils#getVlcp()
	 */
	override
	public String getVlcp() {
		return vlcp;
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see net.pms.io.SystemUtils#getVlcv()
	 */
	override
	public String getVlcv() {
		return vlcv;
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see net.pms.io.SystemUtils#isAvis()
	 */
	override
	public bool isAvis() {
		return avis;
	}

	override
	public void browseURI(String uri) {
		try {
			Desktop.getDesktop().browse(new URI(uri));
		} catch (IOException e) {
			logger.trace("Unable to open the given URI: " ~ uri ~ ".");
		} catch (URISyntaxException e) {
			logger.trace("Unable to open the given URI: " ~ uri ~ ".");
		}
	}

	override
	public bool isNetworkInterfaceLoopback(NetworkInterface ni) {
		return ni.isLoopback();
	}

	override
	public void addSystemTray(immutable LooksFrame frame) {

		if (SystemTray.isSupported()) {
			SystemTray tray = SystemTray.getSystemTray();

			Image trayIconImage = resolveTrayIcon();

			PopupMenu popup = new PopupMenu();
			MenuItem defaultItem = new MenuItem(Messages.getString("LooksFrame.5"));
			MenuItem traceItem = new MenuItem(Messages.getString("LooksFrame.6"));

			defaultItem.addActionListener(new class() ActionListener {
				public void actionPerformed(ActionEvent e) {
					frame.quit();
				}
			});

			traceItem.addActionListener(new class() ActionListener {
				public void actionPerformed(ActionEvent e) {
					frame.setVisible(true);
				}
			});

			popup.add(traceItem);
			popup.add(defaultItem);

			immutable TrayIcon trayIcon = new TrayIcon(trayIconImage, PropertiesUtil.getProjectProperties().get("project.name") + " " + PMS.getVersion(), popup);

			trayIcon.setImageAutoSize(true);
			trayIcon.addActionListener(new class() ActionListener {
				public void actionPerformed(ActionEvent e) {
					frame.setVisible(true);
					frame.setFocusable(true);
				}
			});
			try {
				tray.add(trayIcon);
			} catch (AWTException e) {
				logger._debug("Caught exception", e);
			}
		}
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
	override
	public byte[] getHardwareAddress(NetworkInterface ni) {
		return ni.getHardwareAddress();
	}

	/**
	 * Return the platform specific ping command for the given host address,
	 * ping count and packet size.
	 *
	 * @param hostAddress The host address.
	 * @param count The ping count.
	 * @param packetSize The packet size.
	 * @return The ping command.
	 */
	override
	public String[] getPingCommand(String hostAddress, int count, int packetSize) {
		return [ "ping", /* count */"-c", Integer.toString(count), /* size */
			"-s", Integer.toString(packetSize), hostAddress 
		];
	}

	/**
	 * Return the proper tray icon for the operating system.
	 * 
	 * @return The tray icon.
	 */
	private Image resolveTrayIcon() {
		String icon = "icon-16.png";

		if (Platform.isMac()) {
			icon = "icon-22.png";
		}
		return Toolkit.getDefaultToolkit().getImage(this.getClass().getResource("/resources/images/" ~ icon));
	}
}
