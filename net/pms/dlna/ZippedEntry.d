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
module net.pms.dlna.ZippedEntry;

import net.pms.formats.Format;
import net.pms.util.FileUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.lang.exceptions;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

public class ZippedEntry : DLNAResource , IPushOutput {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!ZippedEntry();
	private File file;
	private String zeName;
	private long length;
	private ZipFile zipFile;

	override
	protected String getThumbnailURL() {
		if (getType() == Format.IMAGE || getType() == Format.AUDIO) {
			// no thumbnail support for now for zipped videos
			return null;
		}

		return super.getThumbnailURL();
	}

	public this(File file, String zeName, long length) {
		this.zeName = zeName;
		this.file = file;
		this.length = length;
	}

	public InputStream getInputStream() {
		return null;
	}

	public String getName() {
		return zeName;
	}

	public long length() {
		if (getPlayer() !is null && getPlayer().type() != Format.IMAGE) {
			return DLNAMediaInfo.TRANS_SIZE;
		}

		return length;
	}

	public bool isFolder() {
		return false;
	}

	// XXX unused
	deprecated
	public long lastModified() {
		return 0;
	}

	override
	public String getSystemName() {
		return FileUtil.getFileNameWithoutExtension(file.getAbsolutePath()) ~ "." ~ FileUtil.getExtension(zeName);
	}

	override
	public bool isValid() {
		checktype();
		setSrtFile(FileUtil.doesSubtitlesExists(file, null));
		return getFormat() !is null;
	}

	override
	public bool isUnderlyingSeekSupported() {
		return length() < MAX_ARCHIVE_SIZE_SEEK;
	}

	override
	public void push(OutputStream _out) {
		Runnable r = dgRunnable( {
			InputStream _in = null;
			try {
				int n = -1;
				byte[] data = new byte[65536];
				zipFile = new ZipFile(file);
				ZipEntry ze = zipFile.getEntry(zeName);
				_in = zipFile.getInputStream(ze);

				while ((n = _in.read(data)) > -1) {
					_out.write(data, 0, n);
				}

				_in.close();
				_in = null;
			} catch (Exception e) {
				LOGGER.error("Unpack error. Possibly harmless.", e);
			} finally {
				try {
					if (_in !is null) {
						_in.close();
					}
					zipFile.close();
					_out.close();
				} catch (IOException e) {
					LOGGER._debug("Caught exception", e);
				}
			}
		});

		(new Thread(r, "Zip Extractor")).start();
	}

	override
	public void resolve() {
		if (getFormat() is null || !getFormat().isVideo()) {
			return;
		}

		bool found = false;

		if (!found) {
			if (getMedia() is null) {
				setMedia(new DLNAMediaInfo());
			}

			found = !getMedia().isMediaparsed() && !getMedia().isParsing();

			if (getFormat() !is null) {
				InputFile input = new InputFile();
				input.setPush(this);
				input.setSize(length());
				getFormat().parse(getMedia(), input, getType());
			}
		}

		super.resolve();
	}

	override
	public InputStream getThumbnailInputStream() {
		if (getMedia() !is null && getMedia().getThumb() !is null) {
			return getMedia().getThumbnailInputStream();
		} else {
			return super.getThumbnailInputStream();
		}
	}
}
