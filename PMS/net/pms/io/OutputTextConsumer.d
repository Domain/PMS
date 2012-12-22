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
module net.pms.io.OutputTextConsumer;

import org.apache.commons.io.IOUtils;
import org.apache.commons.io.LineIterator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

/**
 *  An input stream consumer that stores the consumed lines in a list and optionally logs each line.
 */
public class OutputTextConsumer : OutputConsumer {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!OutputTextConsumer();
	private List/*<String>*/ lines = new ArrayList/*<String>*/();
	private Object linesLock = new Object();
	private bool log;

	public this(InputStream inputStream, bool log) {
		super(inputStream);
		linesLock = new Object();
		this.log = log;
	}

	public void run() {
		LineIterator it = null;

		try {
			it = IOUtils.lineIterator(inputStream, "UTF-8");

			while (it.hasNext()) {
				String line = it.nextLine();

				if (line.length() > 0) {
					addLine(line);
				}

				if (log) {
					LOGGER._debug(line);
				}
			}
		} catch (IOException ioe) {
			LOGGER._debug("Error consuming input stream: %s", ioe.getMessage());
		} catch (IllegalStateException ise) {
			LOGGER._debug("Error reading from closed input stream: %s", ise.getMessage());
		} finally {
			LineIterator.closeQuietly(it); // clean up all associated resources
		}
	}

	private void addLine(String line) {
		synchronized (linesLock) {
			lines.add(line);
		}
	}

	public BufferedOutputFile getBuffer() {
		return null;
	}

	public List/*<String>*/ getResults() {
		List/*<String>*/ clonedResults = new ArrayList/*<String>*/();

		synchronized (linesLock) {
			clonedResults.addAll(lines);
		}

		return clonedResults;
	}
}
