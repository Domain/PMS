/*
 * PS3 Media Server, for streaming any medias to your PS3.
 * Copyright (C) 2008  A.Brochard
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
module net.pms.network.UPNPHelper;

import net.pms.PMS;
import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.exceptions;
import java.net.all;
import java.text.SimpleDateFormat;
import java.util.all;

/**
 * Helper class to handle the UPnP traffic that makes PMS discoverable by other clients.
 * See http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v1.0.pdf
 * and http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v1.1-AnnexA.pdf
 * for the specifications.
 */
public class UPNPHelper {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!UPNPHelper();
	private const static String CRLF = "\r\n";
	private const static String ALIVE = "ssdp:alive";
	
	/**
	 * IPv4 Multicast channel reserved for SSDP by Internet Assigned Numbers Authority (IANA).
	 * MUST be 239.255.255.250.
	 */
	private const static String IPV4_UPNP_HOST = "239.255.255.250";

	/**
	 * IPv6 Multicast channel reserved for SSDP by Internet Assigned Numbers Authority (IANA).
	 * MUST be [FF02::C].
	 */
	private const static String IPV6_UPNP_HOST = "[FF02::C]";

	/**
	 * Multicast channel reserved for SSDP by Internet Assigned Numbers Authority (IANA).
	 * MUST be 1900.
	 */
	private const static int UPNP_PORT = 1900;

	private const static String BYEBYE = "ssdp:byebye";
	private static Thread listener;
	private static Thread aliveThread;
	private static SimpleDateFormat sdf = new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss", Locale.US);

	/**
	 * Send UPnP discovery search message to discover devices of interest on
	 * the network.
	 *
	 * @param host The multicast channel
	 * @param port The multicast port
	 * @param st The search target string
	 * @throws IOException
	 */
	private static void sendDiscover(String host, int port, String st) {
		String usn = PMS.get().usn();
		sdf.setTimeZone(TimeZone.getTimeZone("GMT"));

		if (st.opEquals(usn)) {
			usn = "";
		} else {
			usn ~= "::";
		}

		String discovery =
			"HTTP/1.1 200 OK" ~ CRLF
			~ "CACHE-CONTROL: max-age=1200" ~ CRLF
			~ "DATE: " ~ sdf.format(new Date(System.currentTimeMillis())) ~ " GMT" ~ CRLF
			~ "LOCATION: http://" ~ PMS.get().getServer().getHost() ~ ":" ~ PMS.get().getServer().getPort() ~ "/description/fetch" ~ CRLF
			~ "SERVER: " ~ PMS.get().getServerName() ~ CRLF
			~ "ST: " ~ st ~ CRLF
			~ "EXT: " ~ CRLF
			~ "USN: " ~ usn ~ st ~ CRLF
			~ "Content-Length: 0" ~ CRLF ~ CRLF;
		sendReply(host, port, discovery);
	}

	private static void sendReply(String host, int port, String msg) {
		try {
			DatagramSocket ssdpUniSock = new DatagramSocket();

			logger.trace("Sending this reply [" ~ host ~ ":" ~ port ~ "]: " ~ StringUtils.replace(msg, CRLF, "<CRLF>"));
			InetAddress inetAddr = InetAddress.getByName(host);
			DatagramPacket dgmPacket = new DatagramPacket(msg.getBytes(), msg.length(), inetAddr, port);
			ssdpUniSock.send(dgmPacket);
			ssdpUniSock.close();

		} catch (Exception ex) {
			logger.info(ex.getMessage());
		}
	}

	public static void sendAlive() {
		logger._debug("Sending ALIVE...");

		MulticastSocket ssdpSocket = getNewMulticastSocket();
		sendMessage(ssdpSocket, "upnp:rootdevice", ALIVE);
		sendMessage(ssdpSocket, PMS.get().usn(), ALIVE);
		sendMessage(ssdpSocket, "urn:schemas-upnp-org:device:MediaServer:1", ALIVE);
		sendMessage(ssdpSocket, "urn:schemas-upnp-org:service:ContentDirectory:1", ALIVE);
		sendMessage(ssdpSocket, "urn:schemas-upnp-org:service:ConnectionManager:1", ALIVE);

		ssdpSocket.close();
		ssdpSocket = null;
	}

	private static MulticastSocket getNewMulticastSocket() {
		MulticastSocket ssdpSocket = new MulticastSocket();
		ssdpSocket.setReuseAddress(true);
		NetworkInterface ni = NetworkConfiguration.getInstance().getNetworkInterfaceByServerName();
		if (ni !is null) {
			ssdpSocket.setNetworkInterface(ni);

			// force IPv4 address
			Enumeration/*<InetAddress>*/ enm = ni.getInetAddresses();
			while (enm.hasMoreElements()) {
				InetAddress ia = enm.nextElement();
				if (!(cast(Inet6Address)ia !is null)) {
					ssdpSocket.setInterface(ia);
					break;
				}
			}
		} else if (PMS.get().getServer().getNetworkInterface() !is null) {
			logger.trace("Setting multicast network interface: " ~ PMS.get().getServer().getNetworkInterface());
			ssdpSocket.setNetworkInterface(PMS.get().getServer().getNetworkInterface());
		}
		logger.trace("Sending message from multicast socket on network interface: " ~ ssdpSocket.getNetworkInterface());
		logger.trace("Multicast socket is on interface: " ~ ssdpSocket.getInterface());
		ssdpSocket.setTimeToLive(32);
		ssdpSocket.joinGroup(getUPNPAddress());
		logger.trace("Socket Timeout: " ~ ssdpSocket.getSoTimeout());
		logger.trace("Socket TTL: " ~ ssdpSocket.getTimeToLive());
		return ssdpSocket;
	}

	public static void sendByeBye() {
		logger.info("Sending BYEBYE...");
		MulticastSocket ssdpSocket = getNewMulticastSocket();

		sendMessage(ssdpSocket, "upnp:rootdevice", BYEBYE);
		sendMessage(ssdpSocket, "urn:schemas-upnp-org:device:MediaServer:1", BYEBYE);
		sendMessage(ssdpSocket, "urn:schemas-upnp-org:service:ContentDirectory:1", BYEBYE);
		sendMessage(ssdpSocket, "urn:schemas-upnp-org:service:ConnectionManager:1", BYEBYE);

		ssdpSocket.leaveGroup(getUPNPAddress());
		ssdpSocket.close();
		ssdpSocket = null;

	}

	private static void sleep(int delay) {
		try {
			Thread.sleep(delay);
		} catch (InterruptedException e) {
		}
	}

	private static void sendMessage(DatagramSocket socket, String nt, String message) {
		String msg = buildMsg(nt, message);
		Random rand = new Random();
		//logger.trace( "Sending this SSDP packet: " ~ CRLF ~ msg);// StringUtils.replace(msg, CRLF, "<CRLF>"));
		DatagramPacket ssdpPacket = new DatagramPacket(msg.getBytes(), msg.length(), getUPNPAddress(), UPNP_PORT);
		socket.send(ssdpPacket);
		sleep(rand.nextInt(1800 / 2));

		socket.send(ssdpPacket);
		sleep(rand.nextInt(1800 / 2));
	}
	private static int delay = 10000;

	public static void listen() {
		Runnable rAlive = dgRunnable( {
				while (true) {
					try {
						Thread.sleep(delay);
						sendAlive();
						if (delay == 20000) // every 180s
						{
							delay = 180000;
						}
						if (delay == 10000) // after 10, and 30s
						{
							delay = 20000;
						}
					} catch (Exception e) {
						logger._debug("Error while sending periodic alive message: " ~ e.getMessage());
					}
				}
		});
		aliveThread = new Thread(rAlive, "UPNP-AliveMessageSender");
		aliveThread.start();

		Runnable r = dgRunnable( {
				bool bindErrorReported = false;
				while (true) {
					try {
						// Use configurable source port as per http://code.google.com/p/ps3mediaserver/issues/detail?id=1166
						MulticastSocket socket = new MulticastSocket(PMS.getConfiguration().getUpnpPort());
						if (bindErrorReported) {
							logger.warn("Finally, acquiring port " ~ PMS.getConfiguration().getUpnpPort() ~ " was successful!");
						}
						NetworkInterface ni = NetworkConfiguration.getInstance().getNetworkInterfaceByServerName();
						if (ni !is null) {
							socket.setNetworkInterface(ni);
						} else if (PMS.get().getServer().getNetworkInterface() !is null) {
							logger.trace("Setting multicast network interface: " ~ PMS.get().getServer().getNetworkInterface());
							socket.setNetworkInterface(PMS.get().getServer().getNetworkInterface());
						}
						socket.setTimeToLive(4);
						socket.setReuseAddress(true);
						socket.joinGroup(getUPNPAddress());
						while (true) {
							byte[] buf = new byte[1024];
							DatagramPacket packet_r = new DatagramPacket(buf, buf.length);
							socket.receive(packet_r);

							String s = new String(packet_r.getData());

							InetAddress address = packet_r.getAddress();
							if (s.startsWith("M-SEARCH")) {
								String remoteAddr = address.getHostAddress();
								int remotePort = packet_r.getPort();

								if (PMS.getConfiguration().getIpFiltering().allowed(address)) {
									logger.trace("Receiving a M-SEARCH from [" ~ remoteAddr ~ ":" ~ remotePort ~ "]");

									if (StringUtils.indexOf(s, "urn:schemas-upnp-org:service:ContentDirectory:1") > 0) {
										sendDiscover(remoteAddr, remotePort, "urn:schemas-upnp-org:service:ContentDirectory:1");
									}

									if (StringUtils.indexOf(s, "upnp:rootdevice") > 0) {
										sendDiscover(remoteAddr, remotePort, "upnp:rootdevice");
									}

									if (StringUtils.indexOf(s, "urn:schemas-upnp-org:device:MediaServer:1") > 0) {
										sendDiscover(remoteAddr, remotePort, "urn:schemas-upnp-org:device:MediaServer:1");
									}

									if (StringUtils.indexOf(s, PMS.get().usn()) > 0) {
										sendDiscover(remoteAddr, remotePort, PMS.get().usn());
									}
								}
							} else if (s.startsWith("NOTIFY")) {
								String remoteAddr = address.getHostAddress();
								int remotePort = packet_r.getPort();

								logger.trace("Receiving a NOTIFY from [" ~ remoteAddr ~ ":" ~ remotePort ~ "]");
							}
						}
					} catch (BindException e) {
						if (!bindErrorReported) {
							logger.error("Unable to bind to " ~ PMS.getConfiguration().getUpnpPort()
							~ ", which means that PMS will not automatically appear on your renderer! "
							~ "This usually means that another program occupies the port. Please "
							~ "stop the other program and free up the port. "
							~ "PMS will keep trying to bind to it...[" ~ e.getMessage() ~ "]");
						}
						bindErrorReported = true;
						sleep(5000);
					} catch (IOException e) {
						logger.error("UPNP network exception", e);
						sleep(1000);
					}
				}
		});
		listener = new Thread(r, "UPNPHelper");
		listener.start();
	}

	public static void shutDownListener() {
		listener.interrupt();
		aliveThread.interrupt();
	}

	private static String buildMsg(String nt, String message) {
		StringBuilder sb = new StringBuilder();

		sb.append("NOTIFY * HTTP/1.1" ~ CRLF);
		sb.append("HOST: " ~ IPV4_UPNP_HOST ~ ":").append(UPNP_PORT).append(CRLF);
		sb.append("NT: ").append(nt).append(CRLF);
		sb.append("NTS: ").append(message).append(CRLF);

		if (message.opEquals(ALIVE)) {
			sb.append("LOCATION: http://").append(PMS.get().getServer().getHost()).append(":").append(PMS.get().getServer().getPort()).append("/description/fetch" ~ CRLF);
		}
		sb.append("USN: ").append(PMS.get().usn());
		if (!nt.opEquals(PMS.get().usn())) {
			sb.append("::").append(nt);
		}
		sb.append(CRLF);

		if (message.opEquals(ALIVE)) {
			sb.append("CACHE-CONTROL: max-age=1800" ~ CRLF);
		}

		if (message.opEquals(ALIVE)) {
			sb.append("SERVER: ").append(PMS.get().getServerName()).append(CRLF);
		}

		sb.append(CRLF);
		return sb.toString();
	}

	private static InetAddress getUPNPAddress() {
		return InetAddress.getByAddress(IPV4_UPNP_HOST, [cast(byte) 239, cast(byte) 255, cast(byte) 255, cast(byte) 250]);
	}
}
