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
module net.pms.dlna.RarredEntry;

import com.github.junrar.Archive;
import com.github.junrar.rarfile.FileHeader;

import net.pms.formats.Format;
import net.pms.util.FileUtil;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class RarredEntry : DLNAResource , IPushOutput {
	private static immutable Logger logger = LoggerFactory.getLogger!RarredEntry();
	private String name;
	private File file;
	private String fileHeaderName;
	private long length;

	override
	protected String getThumbnailURL() {
		if (getType() == Format.IMAGE || getType() == Format.AUDIO) { // no thumbnail support for now for rarred videos
			return null;
		}

		return super.getThumbnailURL();
	}

	public this(String name, File file, String fileHeaderName, long length) {
		this.fileHeaderName = fileHeaderName;
		this.name = name;
		this.file = file;
		this.length = length;
	}

	public InputStream getInputStream() {
		return null;
	}

	public String getName() {
		return name;
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
		return FileUtil.getFileNameWithoutExtension(file.getAbsolutePath()) ~ "." ~ FileUtil.getExtension(name);
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
	public void push(immutable OutputStream _out) {
		Runnable r = new class() Runnable {

			public void run() {
				Archive rarFile = null;
				try {
					rarFile = new Archive(file);
					FileHeader header = null;
					foreach (FileHeader fh ; rarFile.getFileHeaders()) {
						if (fh.getFileNameString().opEquals(fileHeaderName)) {
							header = fh;
							break;
						}
					}
					if (header !is null) {
						logger.trace("Starting the extraction of " ~ header.getFileNameString());
						rarFile.extractFile(header, _out);
					}
				} catch (Exception e) {
					logger._debug("Unpack error, maybe it's normal, as backend can be terminated: " ~ e.getMessage());
				} finally {
					try {
						rarFile.close();
						_out.close();
					} catch (IOException e) {
						logger._debug("Caught exception", e);
					}
				}
			}
		};

		(new Thread(r, "Rar Extractor")).start();
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
