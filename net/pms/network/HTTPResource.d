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
module net.pms.network.HTTPResource;

import net.pms.PMS;
import net.pms.configuration.RendererConfiguration;
import net.pms.dlna.DLNAResource;
import net.pms.formats.Format;
import net.pms.util.PropertiesUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.all;
import java.net.Authenticator;
import java.net.URL;
import java.net.URLConnection;

import net.pms.util.StringUtil : convertURLToFileName;

/**
 * Implements any item that can be transfered through the HTTP pipes.
 * In the PMS case, this item represents media files.
 * @see DLNAResource
 */
public class HTTPResource {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!HTTPResource();
	public static const String UNKNOWN_VIDEO_TYPEMIME = "video/mpeg";
	public static const String UNKNOWN_IMAGE_TYPEMIME = "image/jpeg";
	public static const String UNKNOWN_AUDIO_TYPEMIME = "audio/mpeg";
	public static const String AUDIO_MP3_TYPEMIME = "audio/mpeg";
	public static const String AUDIO_MP4_TYPEMIME = "audio/x-m4a";
	public static const String AUDIO_WAV_TYPEMIME = "audio/wav";
	public static const String AUDIO_WMA_TYPEMIME = "audio/x-ms-wma";
	public static const String AUDIO_FLAC_TYPEMIME = "audio/x-flac";
	public static const String AUDIO_OGG_TYPEMIME = "audio/x-ogg";
	public static const String AUDIO_LPCM_TYPEMIME = "audio/L16";
	public static const String MPEG_TYPEMIME = "video/mpeg";
	public static const String MP4_TYPEMIME = "video/mp4";
	public static const String AVI_TYPEMIME = "video/avi";
	public static const String WMV_TYPEMIME = "video/x-ms-wmv";
	public static const String ASF_TYPEMIME = "video/x-ms-asf";
	public static const String MATROSKA_TYPEMIME = "video/x-matroska";
	public static const String VIDEO_TRANSCODE = "video/transcode";
	public static const String AUDIO_TRANSCODE = "audio/transcode";
	public static const String PNG_TYPEMIME = "image/png";
	public static const String JPEG_TYPEMIME = "image/jpeg";
	public static const String TIFF_TYPEMIME = "image/tiff";
	public static const String GIF_TYPEMIME = "image/gif";
	public static const String BMP_TYPEMIME = "image/bmp";

	public this() { }

	/**
	 * Returns for a given item type the default MIME type associated. This is used in the HTTP transfers
	 * as in the client might do different things for different MIME types.
	 * @param type Type for which the default MIME type is needed.
	 * @return Default MIME associated with the file type.
	 */
	public static String getDefaultMimeType(int type) {
		String mimeType = HTTPResource.UNKNOWN_VIDEO_TYPEMIME;

		if (type == Format.VIDEO) {
			mimeType = HTTPResource.UNKNOWN_VIDEO_TYPEMIME;
		} else if (type == Format.IMAGE) {
			mimeType = HTTPResource.UNKNOWN_IMAGE_TYPEMIME;
		} else if (type == Format.AUDIO) {
			mimeType = HTTPResource.UNKNOWN_AUDIO_TYPEMIME;
		}

		return mimeType;
	}

	/**
	 * Returns a InputStream associated with the fileName.
	 * @param fileName TODO Absolute or relative file path.
	 * @return If found, an InputStream associated with the fileName. null otherwise.
	 */
	protected InputStream getResourceInputStream(String fileName) {
		fileName = "/resources/" ~ fileName;
		ClassLoader cll = this.getClass().getClassLoader();
		InputStream _is = cll.getResourceAsStream(fileName.substring(1));

		while (_is is null && cll.getParent() !is null) {
			cll = cll.getParent();
			_is = cll.getResourceAsStream(fileName.substring(1));
		}

		return _is;
	}

	/**
	 * Creates an InputStream based on a URL. This is used while accessing external resources
	 * like online radio stations.
	 * @param u URL.
	 * @param saveOnDisk If true, the file is first downloaded to the temporary folder.
	 * @return InputStream that can be used for sending to the media renderer.
	 * @throws IOException
	 * @see #downloadAndSendBinary(String)
	 */
	protected static InputStream downloadAndSend(String u, bool saveOnDisk) {
		URL url = new URL(u);
		File f = null;

		if (saveOnDisk) {
			String host = url.getHost();
			String hostName = convertURLToFileName(host);
			String fileName = url.getFile();
			fileName = convertURLToFileName(fileName);
			File hostDir = new File(PMS.getConfiguration().getTempFolder(), hostName);

			if (!hostDir.isDirectory()) {
				if (!hostDir.mkdir()) {
					LOGGER._debug("Cannot create directory: %s", hostDir.getAbsolutePath());
				}
			}

			f = new File(hostDir, fileName);

			if (f.exists()) {
				return new FileInputStream(f);
			}
		}

		byte[] content = downloadAndSendBinary(u, saveOnDisk, f);
		return new ByteArrayInputStream(content);
	}

	/**
	 * Overloaded method for {@link #downloadAndSendBinary(String, bool, File)}, without storing a file on the filesystem.
	 * @param u URL to retrieve.
	 * @return byte array.
	 * @throws IOException
	 */
	protected static byte[] downloadAndSendBinary(String u) {
		return downloadAndSendBinary(u, false, null);
	}

	/**
	 * Returns a byte array representation of the file given by the URL. The file is downloaded and optionally stored on the filesystem.
	 * @param u URL to retrieve.
	 * @param saveOnDisk If true, store the file on the filesystem.
	 * @param f If saveOnDisk is true, then store the contents of the file represented by u in the associated File. f needs to be opened before
	 * calling this function.
	 * @return The byte array
	 * @throws IOException
	 */
	protected static byte[] downloadAndSendBinary(String u, bool saveOnDisk, File f) {
		URL url = new URL(u);
		
		// The URL may contain user authentication information
		Authenticator.setDefault(new HTTPResourceAuthenticator());
		HTTPResourceAuthenticator.addURL(url);
		
		LOGGER._debug("Retrieving " ~ url.toString());
		ByteArrayOutputStream bytes = new ByteArrayOutputStream();
		URLConnection conn = url.openConnection();
		// GameTrailers blocks user-agents that identify themselves as "Java"
		conn.setRequestProperty("User-agent", PropertiesUtil.getProjectProperties().get("project.name") ~ " " ~ PMS.getVersion());
		InputStream _in = conn.getInputStream();
		FileOutputStream fOUT = null;

		if (saveOnDisk && f !is null) {
			// fileName = convertURLToFileName(fileName);
			fOUT = new FileOutputStream(f);
		}

		byte[] buf = new byte[4096];
		int n = -1;

		while ((n = _in.read(buf)) > -1) {
			bytes.write(buf, 0, n);

			if (fOUT !is null) {
				fOUT.write(buf, 0, n);
			}
		}

		_in.close();

		if (fOUT !is null) {
			fOUT.close();
		}

		return bytes.toByteArray();
	}

	/**
	 * Returns the supplied MIME type customized for the supplied media renderer according to the renderer's aliasing rules.
	 * @param mimetype MIME type to customize.
	 * @param renderer media renderer to customize the MIME type for.
	 * @return The MIME type
	 */
	public String getRendererMimeType(String mimetype, RendererConfiguration renderer) {
		return renderer.getMimeType(mimetype);
	}

	public int getDLNALocalesCount() {
		return 3;
	}

	public const String getMPEG_PS_PALLocalizedValue(int index) {
		if (index == 1 || index == 2) {
			return "MPEG_PS_NTSC";
		}

		return "MPEG_PS_PAL";
	}

	public const String getMPEG_TS_SD_EU_ISOLocalizedValue(int index) {
		if (index == 1) {
			return "MPEG_TS_SD_NA_ISO";
		}

		if (index == 2) {
			return "MPEG_TS_SD_JP_ISO";
		}

		return "MPEG_TS_SD_EU_ISO";
	}

	public const String getMPEG_TS_SD_EULocalizedValue(int index) {
		if (index == 1) {
			return "MPEG_TS_SD_NA";
		}

		if (index == 2) {
			return "MPEG_TS_SD_JP";
		}

		return "MPEG_TS_SD_EU";
	}
}
