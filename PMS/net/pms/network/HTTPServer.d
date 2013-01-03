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
module net.pms.network.HTTPServer;

import net.pms.PMS;
import net.pms.configuration.PmsConfiguration;
import org.apache.commons.lang.StringUtils;
//import org.jboss.netty.bootstrap.ServerBootstrap;
//import org.jboss.netty.channel.Channel;
//import org.jboss.netty.channel.ChannelFactory;
//import org.jboss.netty.channel.group.ChannelGroup;
//import org.jboss.netty.channel.group.DefaultChannelGroup;
//import org.jboss.netty.channel.socket.nio.NioServerSocketChannelFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.exceptions;
import java.net.all;
import java.nio.channels.ClosedByInterruptException;
import java.nio.channels.ServerSocketChannel;
import java.util.concurrent.Executors;

public class HTTPServer : Runnable {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!HTTPServer();
	private int port;
	private String hostname;
	private ServerSocketChannel serverSocketChannel;
	private ServerSocket serverSocket;
	private bool stop;
	private Thread runnable;
	private InetAddress iafinal;
	private ChannelFactory factory;
	private Channel channel;
	private NetworkInterface networkInterface;
	private ChannelGroup group;

	// XXX not used
	deprecated
	public InetAddress getIafinal() {
		return iafinal;
	}

	public NetworkInterface getNetworkInterface() {
		return networkInterface;
	}

	// use getNetworkInterface()
	deprecated
	public NetworkInterface getNi() {
		return getNetworkInterface();
	}

	public this(int port) {
		this.port = port;
	}

	public String getURL() {
		return "http://" ~ hostname ~ ":" ~ port;
	}

	public String getHost() {
		return hostname;
	}

	public int getPort() {
		return port;
	}

	public bool start() {
		immutable PmsConfiguration configuration = PMS.getConfiguration();
		hostname = configuration.getServerHostname();
		InetSocketAddress address = null;

		if (StringUtils.isNotBlank(hostname)) {
			LOGGER.info("Using forced address " ~ hostname);
			InetAddress tempIA = InetAddress.getByName(hostname);

			if (tempIA !is null && networkInterface !is null && networkInterface.opEquals(NetworkInterface.getByInetAddress(tempIA))) {
				address = new InetSocketAddress(tempIA, port);
			} else {
				address = new InetSocketAddress(hostname, port);
			}
		} else if (isAddressFromInterfaceFound(configuration.getNetworkInterface())) { // XXX sets iafinal and networkInterface
			LOGGER.info("Using address %s found on network interface: %s", iafinal, networkInterface.toString().trim().replace('\n', ' '));
			address = new InetSocketAddress(iafinal, port);
		} else {
			LOGGER.info("Using localhost address");
			address = new InetSocketAddress(port);
		}

		LOGGER.info("Created socket: " ~ address);

		if (configuration.isHTTPEngineV2()) { // HTTP Engine V2
			group = new DefaultChannelGroup("myServer");
			factory = new NioServerSocketChannelFactory(
				Executors.newCachedThreadPool(),
				Executors.newCachedThreadPool()
			);

			ServerBootstrap bootstrap = new ServerBootstrap(factory);
			HttpServerPipelineFactory pipeline = new HttpServerPipelineFactory(group);
			bootstrap.setPipelineFactory(pipeline);
			bootstrap.setOption("child.tcpNoDelay", true);
			bootstrap.setOption("child.keepAlive", true);
			bootstrap.setOption("reuseAddress", true);
			bootstrap.setOption("child.reuseAddress", true);
			bootstrap.setOption("child.sendBufferSize", 65536);
			bootstrap.setOption("child.receiveBufferSize", 65536);
			channel = bootstrap.bind(address);
			group.add(channel);

			if (hostname is null && iafinal !is null) {
				hostname = iafinal.getHostAddress();
			} else if (hostname is null) {
				hostname = InetAddress.getLocalHost().getHostAddress();
			}
		} else { // HTTP Engine V1
			serverSocketChannel = ServerSocketChannel.open();

			serverSocket = serverSocketChannel.socket();
			serverSocket.setReuseAddress(true);
			serverSocket.bind(address);

			if (hostname is null && iafinal !is null) {
				hostname = iafinal.getHostAddress();
			} else if (hostname is null) {
				hostname = InetAddress.getLocalHost().getHostAddress();
			}

			runnable = new Thread(this, "HTTP Server");
			runnable.setDaemon(false);
			runnable.start();
		}

		return true;
	}

	// XXX this sets iafinal and networkInterface
	private bool isAddressFromInterfaceFound(String networkInterfaceName) {
		NetworkConfiguration.InterfaceAssociation ia = StringUtils.isNotEmpty(networkInterfaceName) ?
			NetworkConfiguration.getInstance().getAddressForNetworkInterfaceName(networkInterfaceName) :
			null;

		if (ia is null) {
			ia = NetworkConfiguration.getInstance().getDefaultNetworkInterfaceAddress();
		}

		if (ia !is null) {
			iafinal = ia.getAddr();
			networkInterface = ia.getIface();
		}

		return ia !is null;
	}

	// http://www.ps3mediaserver.org/forum/viewtopic.php?f=6&t=10689&p=48811#p48811
	//
	// avoid a NPE when a) switching HTTP Engine versions and b) restarting the HTTP server
	// by cleaning up based on what's in use (not null) rather than the config state, which
	// might be inconsistent.
	//
	// NOTE: there's little in the way of cleanup to do here as PMS.reset() discards the old
	// server and creates a new one
	public void stop() {
		LOGGER.info("Stopping server on host %s and port %s...", hostname, port);

		if (runnable !is null) { // HTTP Engine V1
			runnable.interrupt();
		}

		if (serverSocket !is null) { // HTTP Engine V1
			try {
				serverSocket.close();
				serverSocketChannel.close();
			} catch (IOException e) {
				LOGGER._debug("Caught exception", e);
			}
		}

		if (channel !is null) { // HTTP Engine V2
			if (group !is null) {
				group.close().awaitUninterruptibly();
			}

			if (factory !is null) {
				factory.releaseExternalResources();
			}
		}

		NetworkConfiguration.forgetConfiguration();
	}

	// XXX only used by HTTP Engine V1
	public void run() {
		LOGGER.info("Starting DLNA Server on host %s and port %s...", hostname, port);

		while (!stop) {
			try {
				Socket socket = serverSocket.accept();
				InetAddress inetAddress = socket.getInetAddress();
				String ip = inetAddress.getHostAddress();
				// basic IP filter: solntcev at gmail dot com
				bool ignore = false;

				if (PMS.getConfiguration().getIpFiltering().allowed(inetAddress)) {
					LOGGER.trace("Receiving a request from: " ~ ip);
				} else {
					ignore = true;
					socket.close();
					LOGGER.trace("Ignoring request from: " ~ ip);
				}

				if (!ignore) {
					RequestHandler request = new RequestHandler(socket);
					Thread thread = new Thread(request, "Request Handler");
					thread.start();
				}
			} catch (ClosedByInterruptException e) {
				stop = true;
			} catch (IOException e) {
				LOGGER._debug("Caught exception", e);
			} finally {
				try {
					if (stop && serverSocket !is null) {
						serverSocket.close();
					}

					if (stop && serverSocketChannel !is null) {
						serverSocketChannel.close();
					}
				} catch (IOException e) {
					LOGGER._debug("Caught exception", e);
				}
			}
		}
	}
}
