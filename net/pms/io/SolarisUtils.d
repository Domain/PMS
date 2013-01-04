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
module net.pms.io.SolarisUtils;

/**
 * Solaris specific platform code 
 * 
 * @author zsombor
 *
 */
public class SolarisUtils : BasicSystemUtils {

	/**
	 * Return the Solaris specific ping command for the given host address,
	 * ping count and packet size:
	 * <p>
	 * <code>ping -s [hostAddress] [packetSize] [numberOfPackets]</code>
	 *
	 * @param hostAddress The host address.
	 * @param numberOfPackets The ping count.
	 * @param packetSize The packet size.
	 * @return The ping command.
	 */
	override
	public String[] getPingCommand(String hostAddress, int numberOfPackets, int packetSize) {
		return [ "ping", "-s",  hostAddress,  /* size */  Integer.toString(packetSize), /* count */  Integer.toString(numberOfPackets) ];
	}

}
