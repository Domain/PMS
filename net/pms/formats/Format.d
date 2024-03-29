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
module net.pms.formats.Format;

import net.pms.configuration.RendererConfiguration;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.dlna.InputFile;
import net.pms.encoders.Player;
import net.pms.network.HTTPResource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.StringTokenizer;

/**
 * Abstract class to store known information about a given format.
 */
public abstract class Format : Cloneable {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!Format();

	public enum Identifier {
		AUDIO_AS_VIDEO,
		DVRMS,
		FLAC,
		GIF,
		ISO,
		JPG,
		M4A,
		MKV,
		MP3,
		MPG,
		OGG,
		PNG,
		RAW,
		TIF,
		WAV,
		WEB,
		CUSTOM
	}

	public int getType() {
		return type;
	}

	public static const int ISO = 32;
	public static const int PLAYLIST = 16;
	public static const int UNKNOWN = 8;
	public static const int VIDEO = 4;
	public static const int AUDIO = 1;
	public static const int IMAGE = 2;

	/**
	 * The identifier (filename extension or protocol) that was matched for a
	 * particular filename or URL. Requires {@link #match(String)} to be called
	 * first.
	 */
	protected String matchedId;

	/**
	 * Returns the identifier (filename extension or protocol) that was matched
	 * for a particular filename or URL. Requires {@link #match(String)} to be
	 * called first.
	 *
	 * @return The matched identifier.
	 */
	public String getMatchedId() {
		return matchedId;
	}
	protected int type = UNKNOWN;
	protected Format secondaryFormat;

	public Format getSecondaryFormat() {
		return secondaryFormat;
	}

	public void setSecondaryFormat(Format secondaryFormat) {
		this.secondaryFormat = secondaryFormat;
	}

	public void setType(int type) {
		if (isUnknown()) {
			this.type = type;
		}
	}

	/**
	 * Returns the identifiers that can be used to identify a particular
	 * format. Valid identifiers are filename extensions or URL protocols,
	 * e.g. "mp3" or "http". Identifiers are expected to be in lower case.
	 *
	 * @return An array of identifiers.
	 */
	public abstract String[] getId();

	/**
	 * @deprecated Use {@link #isCompatible(DLNAMediaInfo, RendererConfiguration)} instead.
	 * <p>
	 * Returns whether or not a format can be handled by the PS3 natively.
	 * This means the format can be streamed to PS3 instead of having to be
	 * transcoded.
	 * 
	 * @return True if the format can be handled by PS3, false otherwise.
	 */
	deprecated
	public abstract bool ps3compatible();
	
	/**
	 * Returns whether or not media can be handled by the renderer natively,
	 * based on the given media information and renderer. If the format can be
	 * streamed (as opposed to having to be transcoded), <code>true</code> will
	 * be returned.
	 * 
	 * @param media
	 *            The media information.
	 * @param renderer
	 *            The renderer for which to check. If <code>null</code> is set
	 *            as renderer, the default renderer configuration will be used.
	 * 
	 * @return True if the format can be handled by the renderer, false
	 *         otherwise.
	 * 
	 * @since 1.50.1
	 */
	public bool isCompatible(DLNAMediaInfo media, RendererConfiguration renderer) {
		RendererConfiguration referenceRenderer;

		if (renderer !is null) {
			// Use the provided renderer as reference
			referenceRenderer = renderer;
		} else {
			// Use the default renderer as reference
			referenceRenderer = RendererConfiguration.getDefaultConf();
		}

		// Let the renderer configuration decide on native compatibility
		return referenceRenderer.isCompatible(media, this);
	}

	public abstract bool transcodable();
	public abstract ArrayList/*<Class<? : Player>>*/ getProfiles();

	public String mimeType() {
		return HTTPResource.getDefaultMimeType(type);
	}

	public bool match(String filename) {
		bool match = false;
		if (filename is null) {
			return match;
		}
		filename = filename.toLowerCase();
		foreach (String singleid ; getId()) {
			String id = singleid.toLowerCase();
			match = filename.endsWith("." ~ id) || filename.startsWith(id ~ "://");
			if (match) {
				matchedId = singleid;
				return true;
			}
		}
		return match;
	}

	public bool isVideo() {
		return (type & VIDEO) == VIDEO;
	}

	public bool isAudio() {
		return (type & AUDIO) == AUDIO;
	}

	public bool isImage() {
		return (type & IMAGE) == IMAGE;
	}

	public bool isUnknown() {
		return (type & UNKNOWN) == UNKNOWN;
	}

	override
	protected Object clone() {
		Object o = null;

		try {
			o = super.clone();
		} catch (CloneNotSupportedException e) {
			LOGGER.error(null, e);
		}

		return o;
	}

	public Format duplicate() {
		return cast(Format) this.clone();
	}

	// method which allows us to fine tune parsing with different formats in the future
	public void parse(DLNAMediaInfo media, InputFile file, int type) {
		parse(media, file, type, null);
	}

	// 2010-02-03 now this is useful :p
	public void parse(DLNAMediaInfo media, InputFile file, int type, RendererConfiguration renderer) {
		if (renderer !is null && renderer.isMediaParserV2()) {
			renderer.getFormatConfiguration().parse(media, file, this, type);
		} else {
			media.parse(file, this, type, false);
		}

		LOGGER.trace("Parsing results: " ~ file ~ " / " ~ media);
	}

	/**
	 * Returns whether or not the matched identifier of this format is among
	 * the list of supplied extensions.
	 *
	 * @param extensions String of comma separated extensions
	 * @param moreExtensions String of comma separated extensions
	 *
	 * @return True if this format matches any extension, false otherwise.
	 *
	 * @see #match(String)
	 */
	public bool skip(String extensions, String moreExtensions) {
		if (extensions !is null && extensions.length() > 0) {
			StringTokenizer st = new StringTokenizer(extensions, ",");

			while (st.hasMoreTokens()) {
				String id = st.nextToken().toLowerCase();

				if (matchedId !is null && matchedId.toLowerCase().opEquals(id)) {
					return true;
				}
			}
		}

		if (moreExtensions !is null && moreExtensions.length() > 0) {
			StringTokenizer st = new StringTokenizer(moreExtensions, ",");

			while (st.hasMoreTokens()) {
				String id = st.nextToken().toLowerCase();

				if (matchedId !is null && matchedId.toLowerCase().opEquals(id)) {
					return true;
				}
			}
		}
		return false;
	}

	/**
	 * Return the class name for string representation.
	 * @return The name.
	 */
	public String toString() {
		return getClass().getSimpleName();
		
	}

	/**
	 * Returns the identifier string for the format.
	 *
	 * @return The identifier string.
	 */
	public abstract Identifier getIdentifier();
}
