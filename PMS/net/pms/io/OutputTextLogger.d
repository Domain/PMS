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
module net.pms.io.OutputTextLogger;

import org.apache.commons.io.IOUtils;
import org.apache.commons.io.LineIterator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.lang.exceptions;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.List;

/**
 *  A version of OutputTextConsumer that a) logs all output to the debug.log and b) doesn't store the output
 */
public class OutputTextLogger : OutputConsumer {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!OutputTextLogger();

	public this(InputStream inputStream) {
		super(inputStream);
	}

	public void run() {
		LineIterator it = null;

		try {
			it = IOUtils.lineIterator(inputStream, "UTF-8");

			while (it.hasNext()) {
				String line = it.nextLine();
				LOGGER._debug(line);
			}
		} catch (IOException ioe) {
			LOGGER._debug("Error consuming input stream: %s", ioe.getMessage());
		} catch (IllegalStateException ise) {
			LOGGER._debug("Error reading from closed input stream: %s", ise.getMessage());
		} finally {
			LineIterator.closeQuietly(it); // clean up all associated resources
		}
	}

	public BufferedOutputFile getBuffer() {
		return null;
	}

	public List/*<String>*/ getResults() {
		return null;
	}
}
