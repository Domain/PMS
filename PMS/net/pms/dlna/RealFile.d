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
module net.pms.dlna.RealFile;

import net.pms.PMS;
import net.pms.formats.Format;
import net.pms.formats.FormatFactory;
import net.pms.util.FileUtil;
import net.pms.util.ProcessUtil;
import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.all;
import java.util.ArrayList;

public class RealFile : MapFile {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!RealFile();

	public this(File file) {
		getConf().getFiles().add(file);
		setLastModified(file.lastModified());
	}

	public this(File file, String name) {
		getConf().getFiles().add(file);
		getConf().setName(name);
		setLastModified(file.lastModified());
	}

	override
	// FIXME: this is called repeatedly for invalid files e.g. files MediaInfo can't parse
	public bool isValid() {
		File file = this.getFile();
		checktype();

		if (getType() == Format.VIDEO && file.exists() && PMS.getConfiguration().isAutoloadSubtitles() && file.getName().length() > 4) {
			setSrtFile(FileUtil.doesSubtitlesExists(file, null));
		}

		bool valid = file.exists() && (getFormat() !is null || file.isDirectory());

		if (valid && getParent().getDefaultRenderer() !is null && getParent().getDefaultRenderer().isMediaParserV2()) {
			// we need to resolve the DLNA resource now
			run();

			if (getMedia() !is null && getMedia().getThumb() is null && getType() != Format.AUDIO) { // MediaInfo retrieves cover art now
				getMedia().setThumbready(false);
			}

			// Given that here getFormat() has already matched some (possibly plugin-defined) format:
			//    Format.UNKNOWN + bad parse = inconclusive
			//    known types    + bad parse = bad/encrypted file
			if (getType() != Format.UNKNOWN && getMedia() !is null && (getMedia().isEncrypted() || getMedia().getContainer() is null || getMedia().getContainer().opEquals(DLNAMediaLang.UND))) {
				valid = false;

				if (getMedia().isEncrypted()) {
					LOGGER.info("The file %s is encrypted. It will be hidden", file.getAbsolutePath());
				} else {
					LOGGER.info("The file %s was badly parsed. It will be hidden", file.getAbsolutePath());
				}
			}

			// XXX isMediaParserV2ThumbnailGeneration is only true for the "default renderer"
			if (getParent().getDefaultRenderer().isMediaParserV2ThumbnailGeneration()) {
				checkThumbnail();
			}
		}

		return valid;
	}

	override
	public InputStream getInputStream() {
		try {
			return new FileInputStream(getFile());
		} catch (FileNotFoundException e) {
			LOGGER._debug("File not found: %s", getFile().getAbsolutePath());
		}

		return null;
	}

	override
	public long length() {
		if (getPlayer() !is null && getPlayer().type() != Format.IMAGE) {
			return DLNAMediaInfo.TRANS_SIZE;
		} else if (getMedia() !is null && getMedia().isMediaparsed()) {
			return getMedia().getSize();
		}

		return getFile().length();
	}

	public bool isFolder() {
		return getFile().isDirectory();
	}

	public File getFile() {
		return getConf().getFiles().get(0);
	}

	override
	public String getName() {
		if (this.getConf().getName() is null) {
			String name = null;
			File file = getFile();

			if (file.getName().trim().opEquals("")) {
				if (PMS.get().isWindows()) {
					name = PMS.get().getRegistry().getDiskLabel(file);
				}

				if (name !is null && name.length() > 0) {
					name = file.getAbsolutePath().substring(0, 1) ~ ":\\ [" ~ name ~ "]";
				} else {
					name = file.getAbsolutePath().substring(0, 1);
				}
			} else {
				name = file.getName();
			}

			this.getConf().setName(name);
		}
		return this.getConf().getName();
	}

	override
	protected void checktype() {
		if (getFormat() is null) {
			setFormat(FormatFactory.getAssociatedExtension(getFile().getAbsolutePath()));
		}

		super.checktype();
	}

	override
	public String getSystemName() {
		return ProcessUtil.getShortFileNameIfWideChars(getFile().getAbsolutePath());
	}

	override
	public void resolve() {
		File file = getFile();

		if (file.isFile() && (getMedia() is null || !getMedia().isMediaparsed())) {
			bool found = false;
			InputFile input = new InputFile();
			input.setFile(file);
			String fileName = file.getAbsolutePath();
			if (getSplitTrack() > 0) {
				fileName ~= "#SplitTrack" ~ getSplitTrack();
			}
			
			if (PMS.getConfiguration().getUseCache()) {
				DLNAMediaDatabase database = PMS.get().getDatabase();

				if (database !is null) {
					ArrayList/*<DLNAMediaInfo>*/ medias = database.getData(fileName, file.lastModified());

					if (medias !is null && medias.size() == 1) {
						setMedia(medias.get(0));
						getMedia().finalize(getType(), input);
						found = true;
					}
				}
			}

			if (!found) {
				if (getMedia() is null) {
					setMedia(new DLNAMediaInfo());
				}

				found = !getMedia().isMediaparsed() && !getMedia().isParsing();

				if (getFormat() !is null) {
					getFormat().parse(getMedia(), input, getType(), getParent().getDefaultRenderer());
				} else { // don't think this will ever happen
					getMedia().parse(input, getFormat(), getType(), false);
				}

				if (found && PMS.getConfiguration().getUseCache()) {
					DLNAMediaDatabase database = PMS.get().getDatabase();

					if (database !is null) {
						database.insertData(fileName, file.lastModified(), getType(), getMedia());
					}
				}
			}
		}

		super.resolve();
	}

	override
	public String getThumbnailContentType() {
		return super.getThumbnailContentType();
	}

	override
	public InputStream getThumbnailInputStream() {
		File file = getFile();
		File cachedThumbnail = null;

		if (getParent() !is null && cast(RealFile)getParent() !is null) {
			cachedThumbnail = (cast(RealFile) getParent()).getPotentialCover();
			File thumbFolder = null;
			bool alternativeCheck = false;

			while (cachedThumbnail is null) {
				if (thumbFolder is null && getType() != Format.IMAGE) {
					thumbFolder = file.getParentFile();
				}

				cachedThumbnail = FileUtil.getFileNameWithNewExtension(thumbFolder, file, "jpg");

				if (cachedThumbnail is null) {
					cachedThumbnail = FileUtil.getFileNameWithNewExtension(thumbFolder, file, "png");
				}

				if (cachedThumbnail is null) {
					cachedThumbnail = FileUtil.getFileNameWithAddedExtension(thumbFolder, file, ".cover.jpg");
				}

				if (cachedThumbnail is null) {
					cachedThumbnail = FileUtil.getFileNameWithAddedExtension(thumbFolder, file, ".cover.png");
				}

				if (alternativeCheck) {
					break;
				}

				if (StringUtils.isNotBlank(PMS.getConfiguration().getAlternateThumbFolder())) {
					thumbFolder = new File(PMS.getConfiguration().getAlternateThumbFolder());
					if (!thumbFolder.isDirectory()) {
						thumbFolder = null;
						break;
					}
				}

				alternativeCheck = true;
			}

			if (file.isDirectory()) {
				cachedThumbnail = FileUtil.getFileNameWithNewExtension(file.getParentFile(), file, "/folder.jpg");
				if (cachedThumbnail is null) {
					cachedThumbnail = FileUtil.getFileNameWithNewExtension(file.getParentFile(), file, "/folder.png");
				}
			}
		}

		bool hasAlreadyEmbeddedCoverArt = getType() == Format.AUDIO && getMedia() !is null && getMedia().getThumb() !is null;

		if (cachedThumbnail !is null && (!hasAlreadyEmbeddedCoverArt || file.isDirectory())) {
			return new FileInputStream(cachedThumbnail);
		} else if (getMedia() !is null && getMedia().getThumb() !is null) {
			return getMedia().getThumbnailInputStream();
		} else {
			return super.getThumbnailInputStream();
		}
	}

	override
	public void checkThumbnail() {
		InputFile input = new InputFile();
		input.setFile(getFile());
		checkThumbnail(input);
	}

	override
	protected String getThumbnailURL() {
		if (getType() == Format.IMAGE && !PMS.getConfiguration().getImageThumbnailsEnabled()) {
			return null;
		}

		StringBuilder sb = new StringBuilder();
		sb.append(PMS.get().getServer().getURL());
		sb.append("/");

		if (getMedia() !is null && getMedia().getThumb() !is null) {
			return super.getThumbnailURL();
		} else if (getType() == Format.AUDIO) {
			if (getParent() !is null && cast(RealFile)getParent() !is null && (cast(RealFile) getParent()).getPotentialCover() !is null) {
				return super.getThumbnailURL();
			}
			return null;
		}

		return super.getThumbnailURL();
	}
}
