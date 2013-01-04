/*
 * PS3 Media Server, for streaming any medias to your PS3.
 * Copyright (C) 2008  A.Brochard
 * Copyright (C) 2012  I. Sokolov
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
module net.pms.dlna.DLNAMediaSubtitle;

import net.pms.formats.v2.SubtitleType;
import net.pms.util.FileUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
//import java.io.FileNotFoundException;
import java.lang.exceptions;

import net.pms.formats.v2.SubtitleType;

/**
 * This class keeps track of the subtitle information for media.
 */
public class DLNAMediaSubtitle : DLNAMediaLang , Cloneable {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!DLNAMediaSubtitle();
	private SubtitleType type = SubtitleType.UNKNOWN;
	private String flavor; // subtrack title / language ?
	private File externalFile;
	private String externalFileCharacterSet;


	/**
	 * Returns whether or not the subtitles are embedded.
	 *
	 * @return True if the subtitles are embedded, false otherwise.
	 * @since 1.51.0
	 */
	public bool isEmbedded() {
		return (externalFile is null);
	}

	/**
	 * Returns whether or not the subtitles are external.
	 *
	 * @return True if the subtitles are external file, false otherwise.
	 * @since 1.70.0
	 */
	public bool isExternal() {
		return !isEmbedded();
	}

	override
	public String toString() {
		return "DLNAMediaSubtitle{" ~
				"id=" ~ getId() ~
				", type=" ~ type ~
				", flavor='" ~ flavor ~ '\'' ~
				", lang='" ~ getLang() ~ '\'' ~
				", externalFile=" ~ externalFile ~
				", externalFileCharacterSet='" ~ externalFileCharacterSet ~ '\'' ~
				'}';
	}

	/**
	 * @deprecated charset is autodetected for text subtitles after setExternalFile()
	 */
	deprecated
	public void checkUnicode() {
	}

	override
	protected Object clone() {
		return super.clone();
	}

	/**
	 * @return the type
	 */
	public SubtitleType getType() {
		return type;
	}

	/**
	 * @param type the type to set
	 */
	public void setType(SubtitleType type) {
		if (type is null) {
			throw new IllegalArgumentException("Can't set null SubtitleType.");
		}
		this.type = type;
	}

	/**
	 * @return the flavor
	 */
	public String getFlavor() {
		return flavor;
	}

	/**
	 * @param flavor the flavor to set
	 */
	public void setFlavor(String flavor) {
		this.flavor = flavor;
	}

	/**
	 * @deprecated use FileUtil.convertFileFromUtf16ToUtf8() for UTF-16 -> UTF-8 conversion.
	 */
	deprecated
	public File getPlayableExternalFile() {
		return getExternalFile();
	}

	/**
	 * @return the externalFile
	 */
	public File getExternalFile() {
		return externalFile;
	}

	/**
	 * @param externalFile the externalFile to set
	 */
	public void setExternalFile(File externalFile) {
		if (externalFile is null) {
			throw new FileNotFoundException("Can't read file: no file supplied");
		} else if (!FileUtil.isFileReadable(externalFile)) {
			throw new FileNotFoundException("Can't read file: " ~ externalFile.getAbsolutePath());
		}

		this.externalFile = externalFile;
		setExternalFileCharacterSet();
	}

	private void setExternalFileCharacterSet() {
		if (type == VOBSUB || type == BMP || type == DIVX || type == PGS) {
			externalFileCharacterSet = null;
		} else {
			try {
				externalFileCharacterSet = FileUtil.getFileCharset(externalFile);
			} catch (IOException ex) {
				externalFileCharacterSet = null;
				LOGGER.warn("Exception during external file charset detection.", ex);
			}
		}
	}

	public String getExternalFileCharacterSet() {
		return externalFileCharacterSet;
	}

	/**
	 * @return true if external subtitles file is UTF-8 encoded, false otherwise.
	 */
	public bool isExternalFileUtf8() {
		return FileUtil.isCharsetUTF8(externalFileCharacterSet);
	}

	/**
	 * @return true if external subtitles file is UTF-16 encoded, false otherwise.
	 */
	public bool isExternalFileUtf16() {
		return FileUtil.isCharsetUTF16(externalFileCharacterSet);
	}

	/**
	 * @return true if external subtitles file is UTF-32 encoded, false otherwise.
	 */
	public bool isExternalFileUtf32() {
		return FileUtil.isCharsetUTF32(externalFileCharacterSet);
	}

	/**
	 * @return true if external subtitles file is UTF-8 or UTF-16 encoded, false otherwise.
	 */
	public bool isExternalFileUtf() {
		return (isExternalFileUtf8() || isExternalFileUtf16() || isExternalFileUtf32());
	}
}
