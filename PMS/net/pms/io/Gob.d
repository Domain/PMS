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
module net.pms.io.Gob;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.lang.exceptions;
import java.io.InputStream;
//import java.io.InputStreamReader;

// "Gob": a cryptic name for (e.g.) StreamGobbler - i.e. a stream
// consumer that reads and discards the stream
public class Gob : Thread {
	private static immutable Logger logger = LoggerFactory.getLogger!Gob();
	BufferedReader _in;

	public this(InputStream _in) {
		this._in = new BufferedReader(new InputStreamReader(_in));
	}

	public void run() {
		String line = null;
		try {
			while ((line = _in.readLine()) !is null) {
				if (!line.startsWith("100")) {
					logger.trace(line);
				}
			}
			_in.close();
		} catch (IOException e) {
			logger.trace("Caught exception", e);
		}

	}
}
