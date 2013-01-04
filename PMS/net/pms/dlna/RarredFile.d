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
module net.pms.dlna.RarredFile;

//import com.github.junrar.Archive;
//import com.github.junrar.exception.RarException;
//import com.github.junrar.rarfile.FileHeader;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileInputStream;
import java.lang.exceptions;
import java.io.InputStream;
import java.util.List;

public class RarredFile : DLNAResource {
	private static immutable Logger logger = LoggerFactory.getLogger!RarredFile();
	private File f;
	private Archive rarFile;

	public this(File f) {
		this.f = f;
		setLastModified(f.lastModified());

		try {
			rarFile = new Archive(f);
			List/*<FileHeader>*/ headers = rarFile.getFileHeaders();

			foreach (FileHeader fh ; headers) {
				// if (fh.getFullUnpackSize() < MAX_ARCHIVE_ENTRY_SIZE && fh.getFullPackSize() < MAX_ARCHIVE_ENTRY_SIZE)
				addChild(new RarredEntry(fh.getFileNameString(), f, fh.getFileNameString(), fh.getFullUnpackSize()));
			}

			rarFile.close();
		} catch (RarException e) {
			logger.error(null, e);
		} catch (IOException e) {
			logger.error(null, e);
		}
	}

	public InputStream getInputStream() {
		return new FileInputStream(f);
	}

	public String getName() {
		return f.getName();
	}

	public long length() {
		return f.length();
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
		return f.getAbsolutePath();
	}

	override
	public bool isValid() {
		bool t = false;

		try {
			t = f.exists() && !rarFile.isEncrypted();
		} catch (Throwable th) {
			logger._debug("Caught exception", th);
		}

		return t;
	}
}
