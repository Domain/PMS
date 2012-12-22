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
module net.pms.dlna.ZippedFile;

import net.pms.formats.Format;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.all;
import java.util.Enumeration;
import java.util.zip.ZipEntry;
import java.util.zip.ZipException;
import java.util.zip.ZipFile;
import java.util.zip.ZipInputStream;

public class ZippedFile : DLNAResource {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!ZippedFile();
	private File file;
	private ZipFile zip;

	public this(File file) {
		this.file = file;
		setLastModified(file.lastModified());

		try {
			zip = new ZipFile(file);
			Enumeration/*<? : ZipEntry>*/ enm = zip.entries();

			while (enm.hasMoreElements()) {
				ZipEntry ze = enm.nextElement();
				addChild(new ZippedEntry(file, ze.getName(), ze.getSize()));
			}

			zip.close();
		} catch (ZipException e) {
			LOGGER.error("Error reading zip file", e);
		} catch (IOException e) {
			LOGGER.error("Error reading zip file", e);
		}
	}

	override
	protected String getThumbnailURL() {
		if (getType() == Format.IMAGE) {
			// no thumbnail support for now for zip files
			return null;
		}

		return super.getThumbnailURL();
	}

	public InputStream getInputStream() {
		try {
			return new ZipInputStream(new FileInputStream(file));
		} catch (FileNotFoundException e) {
			throw new RuntimeException(e);
		}
	}

	public String getName() {
		return file.getName();
	}

	public long length() {
		return file.length();
	}

	public bool isFolder() {
		return true;
	}

	// XXX unused
	deprecated
	public long lastModified() {
		return 0;
	}

	override
	public String getSystemName() {
		return file.getAbsolutePath();
	}

	override
	public bool isValid() {
		return file.exists();
	}
}
