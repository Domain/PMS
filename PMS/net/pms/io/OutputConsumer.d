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
module net.pms.io.OutputConsumer;

import org.apache.commons.io.IOUtils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.exceptions;
import java.io.InputStream;
import java.util.List;

public abstract class OutputConsumer : Thread {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!OutputConsumer();
	protected InputStream inputStream;

	public this(InputStream inputStream) {
		this.inputStream = inputStream;
	}

	deprecated
	public void destroy() {
		IOUtils.closeQuietly(inputStream);
	}

	public abstract BufferedOutputFile getBuffer();

	public abstract List/*<String>*/ getResults();
}
