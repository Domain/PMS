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
module net.pms.util.PropertiesUtil;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.exceptions;

public class PropertiesUtil {
	/**
	 * Logs messages to all different channels.
	 */
	private static immutable Logger LOGGER = LoggerFactory.getLogger!PropertiesUtil();

	/**
	 * General properties for the PMS project.
	 */
	private static immutable PmsProperties projectProperties = new PmsProperties();

	static this() {
		try {
			// Read project properties resource file.
			projectProperties.loadFromResourceFile("/resources/project.properties");
		} catch (IOException e) {
			LOGGER.error("Could not load project.properties");
		}
	}

	/**
	 * Returns the project properties object that is constructed from the
	 * "project.properties" file.
	 * <p>
	 * Note that in the Maven "test" phase (e.g. when running PMS from Eclipse)
	 * the file "src/test/resources/project.properties" is used, whereas in
	 * other phases, the file "src/main/resources/project.properties" (e.g. when
	 * packaging the final build) will be used.
	 * 
	 * @return The properties object.
	 */
	public static PmsProperties getProjectProperties() {
		return projectProperties;
	}
}
