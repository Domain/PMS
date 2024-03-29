module net.pms.configuration.RendererConfiguration;

import com.sun.jna.Platform;

import net.pms.Messages;
import net.pms.PMS;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.dlna.LibMediaInfoParser;
import net.pms.dlna.RootFolder;
import net.pms.formats.Format;
import net.pms.network.HTTPResource;
import net.pms.network.SpeedStats;
import net.pms.util.PropertiesUtil;

//import org.apache.commons.configuration.ConfigurationException;
//import org.apache.commons.configuration.ConversionException;
//import org.apache.commons.configuration.PropertiesConfiguration;
import org.apache.commons.lang.StringUtils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.net.InetAddress;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.StringTokenizer;
import java.util.regex.Pattern;

public class RendererConfiguration {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!RendererConfiguration();
	private static ArrayList/*<RendererConfiguration>*/ rendererConfs;
	private static PmsConfiguration pmsConfiguration;
	private static RendererConfiguration defaultConf;
	private static Map/*<InetAddress, RendererConfiguration>*/ addressAssociation = new HashMap/*<InetAddress, RendererConfiguration>*/();

	private RootFolder rootFolder;
	private immutable PropertiesConfiguration configuration;
	private FormatConfiguration formatConfiguration;
	private int rank;
	private immutable Map/*<String, String>*/ mimes;
	private immutable Map/*<String, String>*/ DLNAPN;

	// property values
	private static const String DEPRECATED_MPEGPSAC3 = "MPEGAC3"; // XXX deprecated: old name with missing container
	private static const String EXCLUSIVE = "exclusive";
	private static const String LPCM = "LPCM";
	private static const String MP3 = "MP3";
	private static const String MPEGPSAC3 = "MPEGPSAC3";
	private static const String MPEGTSAC3 = "MPEGTSAC3";
	private static const String WAV = "WAV";
	private static const String WMV = "WMV";

	// property names
	private static const String AUDIO = "Audio";
	private static const String AUTO_EXIF_ROTATE = "AutoExifRotate";
	private static const String BYTE_TO_TIMESEEK_REWIND_SECONDS = "ByteToTimeseekRewindSeconds"; // Ditlew
	private static const String CBR_VIDEO_BITRATE = "CBRVideoBitrate"; // Ditlew
	private static const String CHUNKED_TRANSFER = "ChunkedTransfer";
	private static const String CUSTOM_MENCODER_OPTIONS = "CustomMencoderOptions";
	private static const String CUSTOM_MENCODER_QUALITY_SETTINGS = "CustomMencoderQualitySettings";
	private static const String DEFAULT_VBV_BUFSIZE = "DefaultVBVBufSize";
	private static const String DLNA_LOCALIZATION_REQUIRED = "DLNALocalizationRequired";
	private static const String DLNA_ORGPN_USE = "DLNAOrgPN";
	private static const String DLNA_PN_CHANGES = "DLNAProfileChanges";
	private static const String DLNA_TREE_HACK = "CreateDLNATreeFaster";
	private static const String FORCE_JPG_THUMBNAILS = "ForceJPGThumbnails"; // Sony devices require JPG thumbnails
	private static const String H264_L41_LIMITED = "H264Level41Limited";
	private static const String IMAGE = "Image";
	private static const String LONG_FILE_NAME_FORMAT = "LongFileNameFormat";
	private static const String MAX_VIDEO_BITRATE = "MaxVideoBitrateMbps";
	private static const String MAX_VIDEO_HEIGHT = "MaxVideoHeight";
	private static const String MAX_VIDEO_WIDTH = "MaxVideoWidth";
	private static const String MEDIAPARSERV2 = "MediaInfo";
	private static const String MEDIAPARSERV2_THUMB = "MediaParserV2_ThumbnailGeneration";
	private static const String MIME_TYPES_CHANGES = "MimeTypesChanges";
	private static const String MUX_DTS_TO_MPEG = "MuxDTSToMpeg";
	private static const String MUX_H264_WITH_MPEGTS = "MuxH264ToMpegTS";
	private static const String MUX_LPCM_TO_MPEG = "MuxLPCMToMpeg";
	private static const String RENDERER_ICON = "RendererIcon";
	private static const String RENDERER_NAME = "RendererName";
	private static const String SEEK_BY_TIME = "SeekByTime";
	private static const String SHORT_FILE_NAME_FORMAT = "ShortFileNameFormat";
	private static const String SHOW_AUDIO_METADATA = "ShowAudioMetadata";
	private static const String SHOW_DVD_TITLE_DURATION = "ShowDVDTitleDuration"; // Ditlew
	private static const String SHOW_SUB_METADATA = "ShowSubMetadata";
	private static const String STREAM_EXT = "StreamExtensions";
	private static const String SUBTITLE_HTTP_HEADER = "SubtitleHttpHeader";
	private static const String SUPPORTED = "Supported";
	private static const String TRANSCODE_AUDIO_441KHZ = "TranscodeAudioTo441kHz";
	private static const String TRANSCODE_AUDIO = "TranscodeAudio";
	private static const String TRANSCODED_SIZE = "TranscodedVideoFileSize";
	private static const String TRANSCODE_EXT = "TranscodeExtensions";
	private static const String TRANSCODE_FAST_START = "TranscodeFastStart";
	private static const String TRANSCODE_VIDEO = "TranscodeVideo";
	private static const String USER_AGENT_ADDITIONAL_HEADER = "UserAgentAdditionalHeader";
	private static const String USER_AGENT_ADDITIONAL_SEARCH = "UserAgentAdditionalHeaderSearch";
	private static const String USER_AGENT = "UserAgentSearch";
	private static const String USE_SAME_EXTENSION = "UseSameExtension";
	private static const String VIDEO = "Video";
	private static const String WRAP_DTS_INTO_PCM = "WrapDTSIntoPCM";

	public static RendererConfiguration getDefaultConf() {
		return defaultConf;
	}

	/**
	 * Load all renderer configuration files and set up the default renderer.
	 *
	 * @param pmsConf
	 */
	public static void loadRendererConfigurations(PmsConfiguration pmsConf) {
		pmsConfiguration = pmsConf;
		rendererConfs = new ArrayList/*<RendererConfiguration>*/();

		try {
			defaultConf = new RendererConfiguration();
		} catch (ConfigurationException e) {
			LOGGER._debug("Caught exception", e);
		}

		File renderersDir = getRenderersDir();

		if (renderersDir !is null) {
			LOGGER.info("Loading renderer configurations from " ~ renderersDir.getAbsolutePath());

			File[] confs = renderersDir.listFiles();
			int rank = 1;
			foreach (File f ; confs) {
				if (f.getName().endsWith(".conf")) {
					try {
						LOGGER.info("Loading configuration file: " ~ f.getName());
						RendererConfiguration r = new RendererConfiguration(f);
						r.rank = rank++;
						rendererConfs.add(r);
					} catch (ConfigurationException ce) {
						LOGGER.info("Error in loading configuration of: " ~ f.getAbsolutePath());
					}

				}
			}
		}

		if (rendererConfs.size() > 0) {
			// See if a different default configuration was configured
			String rendererFallback = pmsConfiguration.getRendererDefault();

			if (StringUtils.isNotBlank(rendererFallback)) {
				RendererConfiguration fallbackConf = getRendererConfigurationByName(rendererFallback);

				if (fallbackConf !is null) {
					// A valid fallback configuration was set, use it as default.
					defaultConf = fallbackConf;
				}
			}
		}
	}

	/**
	 * Returns the list of all renderer configurations.
	 *
	 * @return The list of all configurations.
	 */
	public static ArrayList/*<RendererConfiguration>*/ getAllRendererConfigurations() {
		return rendererConfs;
	}

	protected static File getRenderersDir() {
		const String[] pathList = PropertiesUtil.getProjectProperties().get("project.renderers.dir").split(",");

		foreach (String path ; pathList) {
			if (path.trim().length() > 0) {
				File file = new File(path.trim());

				if (file.isDirectory()) {
					if (file.canRead()) {
						return file;
					} else {
						LOGGER.warn("Can't read directory: " ~ file.getAbsolutePath());
					}
				}
			}
		}

		return null;
	}

	public static void resetAllRenderers() {
		foreach (RendererConfiguration rc ; rendererConfs) {
			rc.rootFolder = null;
		}
	}

	public RootFolder getRootFolder() {
		if (rootFolder is null) {
			rootFolder = new RootFolder();
			rootFolder.discoverChildren();
		}

		return rootFolder;
	}

	/**
	 * Associate an IP address with this renderer. The association will
	 * persist between requests, allowing the renderer to be recognized
	 * by its address in later requests.
	 * @param sa The IP address to associate.
	 * @see #getRendererConfigurationBySocketAddress(InetAddress)
	 */
	public void associateIP(InetAddress sa) {
		addressAssociation.put(sa, this);
		SpeedStats.getInstance().getSpeedInMBits(sa, getRendererName());
	}

	public static RendererConfiguration getRendererConfigurationBySocketAddress(InetAddress sa) {
		return addressAssociation.get(sa);
	}

	/**
	 * Tries to find a matching renderer configuration based on a request
	 * header line with a User-Agent header. These matches are made using
	 * the "UserAgentSearch" configuration option in a renderer.conf.
	 * Returns the matched configuration or <code>null</code> if no match
	 * could be found.
	 *
	 * @param userAgentString The request header line.
	 * @return The matching renderer configuration or <code>null</code>.
	 */
	public static RendererConfiguration getRendererConfigurationByUA(String userAgentString) {
		if (pmsConfiguration.isRendererForceDefault()) {
			// Force default renderer
			LOGGER.trace("Forcing renderer match to \"" ~ defaultConf.getRendererName() ~ "\"");
			return manageRendererMatch(defaultConf);
		} else {
			// Try to find a match
			foreach (RendererConfiguration r ; rendererConfs) {
				if (r.matchUserAgent(userAgentString)) {
					return manageRendererMatch(r);
				}
			}
		}

		return null;
	}

	private static RendererConfiguration manageRendererMatch(RendererConfiguration r) {
		if (addressAssociation.values().contains(r)) {
			// FIXME: This cannot ever ever happen because of how renderer matching
			// is implemented in RequestHandler and RequestHandlerV2. The first header
			// match will associate the IP address with the renderer and from then on
			// all other requests from the same IP address will be recognized based on
			// that association. Headers will be ignored and unfortunately they happen
			// to be the only way to get here.
			LOGGER.info("Another renderer like " ~ r.getRendererName() ~ " was found!");
		}

		return r;
	}

	/**
	 * Tries to find a matching renderer configuration based on a request
	 * header line with an additional, non-User-Agent header. These matches
	 * are made based on the "UserAgentAdditionalHeader" and
	 * "UserAgentAdditionalHeaderSearch" configuration options in a
	 * renderer.conf. Returns the matched configuration or <code>null</code>
	 * if no match could be found.
	 *
	 * @param header The request header line.
	 * @return The matching renderer configuration or <code>null</code>.
	 */
	public static RendererConfiguration getRendererConfigurationByUAAHH(String header) {
		if (pmsConfiguration.isRendererForceDefault()) {
			// Force default renderer
			LOGGER.trace("Forcing renderer match to \"" ~ defaultConf.getRendererName() ~ "\"");
			return manageRendererMatch(defaultConf);
		} else {
			// Try to find a match
			foreach (RendererConfiguration r ; rendererConfs) {
				if (StringUtils.isNotBlank(r.getUserAgentAdditionalHttpHeader()) && header.startsWith(r.getUserAgentAdditionalHttpHeader())) {
					String value = header.substring(header.indexOf(":", r.getUserAgentAdditionalHttpHeader().length()) + 1);
					if (r.matchAdditionalUserAgent(value)) {
						return manageRendererMatch(r);
					}
				}
			}
		}

		return null;
	}

	/**
	 * Tries to find a matching renderer configuration based on the name of
	 * the renderer. Returns true if the provided name is equal to or a
	 * substring of the renderer name defined in a configuration, where case
	 * does not matter.
	 *
	 * @param name The renderer name to match.
	 * @return The matching renderer configuration or <code>null</code>
	 *
	 * @since 1.50.1
	 */
	public static RendererConfiguration getRendererConfigurationByName(String name) {
		foreach (RendererConfiguration conf ; rendererConfs) {
			if (conf.getRendererName().toLowerCase().contains(name.toLowerCase())) {
				return conf;
			}
		}

		return null;
	}

	public FormatConfiguration getFormatConfiguration() {
		return formatConfiguration;
	}

	public int getRank() {
		return rank;
	}

	// FIXME These 'is' methods should disappear. Use feature detection instead.
	deprecated
	public bool isXBOX() {
		return getRendererName().toUpperCase().contains("XBOX");
	}

	deprecated
	public bool isXBMC() {
		return getRendererName().toUpperCase().contains("XBMC");
	}

	public bool isPS3() {
		return getRendererName().toUpperCase().contains("PLAYSTATION") || getRendererName().toUpperCase().contains("PS3");
	}

	public bool isBRAVIA() {
		return getRendererName().toUpperCase().contains("BRAVIA");
	}

	deprecated
	public bool isFDSSDP() {
		return getRendererName().toUpperCase().contains("FDSSDP");
	}

	// Ditlew
	public int getByteToTimeseekRewindSeconds() {
		return getInt(BYTE_TO_TIMESEEK_REWIND_SECONDS, 0);
	}

	// Ditlew
	public int getCBRVideoBitrate() {
		return getInt(CBR_VIDEO_BITRATE, 0);
	}

	// Ditlew
	public bool isShowDVDTitleDuration() {
		return getBoolean(SHOW_DVD_TITLE_DURATION, false);
	}

	private this() {
		this(null);
	}

	public this(File f) {
		configuration = new PropertiesConfiguration();
		configuration.setListDelimiter(cast(char) 0);

		if (f !is null) {
			configuration.load(f);
		}

		mimes = new HashMap/*<String, String>*/();
		String mimeTypes = getString(MIME_TYPES_CHANGES, null);

		if (StringUtils.isNotBlank(mimeTypes)) {
			StringTokenizer st = new StringTokenizer(mimeTypes, "|");

			while (st.hasMoreTokens()) {
				String mime_change = st.nextToken().trim();
				int equals = mime_change.indexOf("=");

				if (equals > -1) {
					String old = mime_change.substring(0, equals).trim().toLowerCase();
					String nw = mime_change.substring(equals + 1).trim().toLowerCase();
					mimes.put(old, nw);
				}
			}
		}

		DLNAPN = new HashMap/*<String, String>*/();
		String DLNAPNchanges = getString(DLNA_PN_CHANGES, null);

		if (DLNAPNchanges !is null) {
			LOGGER.trace("Config DLNAPNchanges: " ~ DLNAPNchanges);
		}

		if (StringUtils.isNotBlank(DLNAPNchanges)) {
			StringTokenizer st = new StringTokenizer(DLNAPNchanges, "|");
			while (st.hasMoreTokens()) {
				String DLNAPN_change = st.nextToken().trim();
				int equals = DLNAPN_change.indexOf("=");
				if (equals > -1) {
					String old = DLNAPN_change.substring(0, equals).trim().toUpperCase();
					String nw = DLNAPN_change.substring(equals + 1).trim().toUpperCase();
					DLNAPN.put(old, nw);
				}
			}
		}

		if (f is null) {
			// the default renderer supports everything !
			configuration.addProperty(MEDIAPARSERV2, true);
			configuration.addProperty(MEDIAPARSERV2_THUMB, true);
			configuration.addProperty(SUPPORTED, "f:.+");
		}

		if (isMediaParserV2()) {
			formatConfiguration = new FormatConfiguration(configuration.getList(SUPPORTED));
		}
	}

	public String getDLNAPN(String old) {
		if (DLNAPN.containsKey(old)) {
			return DLNAPN.get(old);
		}
		return old;
	}

	public bool supportsFormat(Format f) {
		switch (f.getType()) {
			case Format.VIDEO:
				return isVideoSupported();
			case Format.AUDIO:
				return isAudioSupported();
			case Format.IMAGE:
				return isImageSupported();
			default:
				break;
		}

		return false;
	}

	public bool isVideoSupported() {
		return getBoolean(VIDEO, true);
	}

	public bool isAudioSupported() {
		return getBoolean(AUDIO, true);
	}

	public bool isImageSupported() {
		return getBoolean(IMAGE, true);
	}

	public bool isTranscodeToWMV() {
		return getVideoTranscode().opEquals(WMV);
	}

	public bool isTranscodeToAC3() {
		return isTranscodeToMPEGPSAC3() || isTranscodeToMPEGTSAC3();
	}

	public bool isTranscodeToMPEGPSAC3() {
		String videoTranscode = getVideoTranscode();
		return videoTranscode.opEquals(MPEGPSAC3) || videoTranscode.opEquals(DEPRECATED_MPEGPSAC3);
	}

	public bool isTranscodeToMPEGTSAC3() {
		return getVideoTranscode().opEquals(MPEGTSAC3);
	}

	public bool isAutoRotateBasedOnExif() {
		return getBoolean(AUTO_EXIF_ROTATE, false);
	}

	public bool isTranscodeToMP3() {
		return getAudioTranscode().opEquals(MP3);
	}

	public bool isTranscodeToLPCM() {
		return getAudioTranscode().opEquals(LPCM);
	}

	public bool isTranscodeToWAV() {
		return getAudioTranscode().opEquals(WAV);
	}

	public bool isTranscodeAudioTo441() {
		return getBoolean(TRANSCODE_AUDIO_441KHZ, false);
	}

	public bool isH264Level41Limited() {
		return getBoolean(H264_L41_LIMITED, false);
	}

	public bool isTranscodeFastStart() {
		return getBoolean(TRANSCODE_FAST_START, false);
	}

	public bool isDLNALocalizationRequired() {
		return getBoolean(DLNA_LOCALIZATION_REQUIRED, false);
	}

	public String getMimeType(String mimetype) {
		if (isMediaParserV2()) {
			if (mimetype !is null && mimetype.opEquals(HTTPResource.VIDEO_TRANSCODE)) {
				mimetype = getFormatConfiguration().match(FormatConfiguration.MPEGPS, FormatConfiguration.MPEG2, FormatConfiguration.AC3);
				if (isTranscodeToMPEGTSAC3()) {
					mimetype = getFormatConfiguration().match(FormatConfiguration.MPEGTS, FormatConfiguration.MPEG2, FormatConfiguration.AC3);
				} else if (isTranscodeToWMV()) {
					mimetype = getFormatConfiguration().match(FormatConfiguration.WMV, FormatConfiguration.WMV, FormatConfiguration.WMA);
				}
			} else if (mimetype !is null && mimetype.opEquals(HTTPResource.AUDIO_TRANSCODE)) {
				mimetype = getFormatConfiguration().match(FormatConfiguration.LPCM, null, null);

				if (mimetype !is null) {
					if (isTranscodeAudioTo441()) {
						mimetype ~= ";rate=44100;channels=2";
					} else {
						mimetype ~= ";rate=48000;channels=2";
					}
				}

				if (isTranscodeToWAV()) {
					mimetype = getFormatConfiguration().match(FormatConfiguration.WAV, null, null);
				} else if (isTranscodeToMP3()) {
					mimetype = getFormatConfiguration().match(FormatConfiguration.MP3, null, null);
				}
			}

			return mimetype;
		}

		if (mimetype !is null && mimetype.opEquals(HTTPResource.VIDEO_TRANSCODE)) {
			mimetype = HTTPResource.MPEG_TYPEMIME;
			if (isTranscodeToWMV()) {
				mimetype = isMediaParserV2()
					? getFormatConfiguration().match(FormatConfiguration.WMV, FormatConfiguration.WMV, FormatConfiguration.WMA)
					: HTTPResource.WMV_TYPEMIME;
			} else if (isTranscodeToMPEGTSAC3()) {
				mimetype = isMediaParserV2()
					? getFormatConfiguration().match(FormatConfiguration.MPEGTS, FormatConfiguration.MPEG2, FormatConfiguration.AC3)
					: HTTPResource.MPEG_TYPEMIME;
			} else { // default: MPEGPSAC3
				mimetype = isMediaParserV2()
					? getFormatConfiguration().match(FormatConfiguration.MPEGPS, FormatConfiguration.MPEG2, FormatConfiguration.AC3)
					: HTTPResource.MPEG_TYPEMIME;
			}
		} else if (mimetype.opEquals(HTTPResource.AUDIO_TRANSCODE)) {
			if (isTranscodeToWAV()) {
				mimetype = isMediaParserV2()
					? getFormatConfiguration().match(FormatConfiguration.WAV, null, null)
					: HTTPResource.AUDIO_WAV_TYPEMIME;
			} else if (isTranscodeToMP3()) {
				mimetype = isMediaParserV2()
					? getFormatConfiguration().match(FormatConfiguration.MP3, null, null)
					: HTTPResource.AUDIO_MP3_TYPEMIME;
			} else { // default: LPCM
				mimetype = isMediaParserV2()
					? getFormatConfiguration().match(FormatConfiguration.LPCM, null, null)
					: HTTPResource.AUDIO_LPCM_TYPEMIME;

				if (isTranscodeAudioTo441()) {
					mimetype ~= ";rate=44100;channels=2";
				} else {
					mimetype ~= ";rate=48000;channels=2";
				}
			}

			if (isTranscodeToMP3()) {
				mimetype = HTTPResource.AUDIO_MP3_TYPEMIME;
			}

			if (isTranscodeToWAV()) {
				mimetype = HTTPResource.AUDIO_WAV_TYPEMIME;
			}
		}

		if (mimes.containsKey(mimetype)) {
			return mimes.get(mimetype);
		}

		return mimetype;
	}

	/**
	 * Pattern match a user agent header string to the "UserAgentSearch"
	 * expression for this renderer. Will return false when the pattern is
	 * empty or when no match can be made.
	 *
	 * @param header The header containing the user agent.
	 * @return True if the pattern matches.
	 */
	public bool matchUserAgent(String header) {
		String userAgent = getUserAgent();
		Pattern userAgentPattern = null;

		if (StringUtils.isNotBlank(userAgent)) {
			userAgentPattern = Pattern.compile(userAgent, Pattern.CASE_INSENSITIVE);

			return userAgentPattern.matcher(header).find();
		} else {
			return false;
		}
	}

	/**
	 * Pattern match a header string to the "UserAgentAdditionalHeaderSearch"
	 * expression for this renderer. Will return false when the pattern is
	 * empty or when no match can be made.
	 *
	 * @param header The additional header string.
	 * @return True if the pattern matches.
	 */
	public bool matchAdditionalUserAgent(String header) {
		String userAgentAdditionalHeader = getUserAgentAdditionalHttpHeaderSearch();
		Pattern userAgentAddtionalPattern = null;

		if (StringUtils.isNotBlank(userAgentAdditionalHeader)) {
			userAgentAddtionalPattern = Pattern.compile(userAgentAdditionalHeader, Pattern.CASE_INSENSITIVE);

			return userAgentAddtionalPattern.matcher(header).find();
		} else {
			return false;
		}
	}

	/**
	 * Returns the pattern to match the User-Agent header to as defined in the
	 * renderer configuration. Default value is "".
	 *
	 * @return The User-Agent search pattern.
	 */
	public String getUserAgent() {
		return getString(USER_AGENT, "");
	}

	/**
	 * RendererName: Determines the name that is displayed in the PMS user
	 * interface when this renderer connects. Default value is "Unknown
	 * renderer".
	 *
	 * @return The renderer name.
	 */
	public String getRendererName() {
		return getString(RENDERER_NAME, Messages.getString("PMS.17"));
	}

	/**
	 * Returns the icon to use for displaying this renderer in PMS as defined
	 * in the renderer configurations. Default value is "unknown.png".
	 *
	 * @return The renderer icon.
	 */
	public String getRendererIcon() {
		return getString(RENDERER_ICON, "unknown.png");
	}

	/**
	 * LongFileNameFormat: Determines how media file names are formatted in the
	 * regular folders. All supported formatting options are described in
	 * {@link net.pms.dlna.DLNAResource#getDisplayName(RendererConfiguration)
	 * getDisplayName(RendererConfiguration)}.
	 *
	 * @return The format for file names in the regular folders.
	 */
	public String getLongFileNameFormat() {
		return getString(LONG_FILE_NAME_FORMAT, Messages.getString("DLNAResource.4"));
	}

	/**
	 * ShortFileNameFormat: Determines how media file names are formatted in the
	 * transcoding virtual folder. All supported formatting options are described in
	 * {@link net.pms.dlna.DLNAResource#getDisplayName(RendererConfiguration)
	 * getDisplayName(RendererConfiguration)}.
	 *
	 * @return The format for file names in the transcoding virtual folder.
	 */
	public String getShortFileNameFormat() {
		return getString(SHORT_FILE_NAME_FORMAT, Messages.getString("DLNAResource.3"));
	}

	/**
	 * Returns the the name of an additional HTTP header whose value should
	 * be matched with the additional header search pattern. The header name
	 * must be an exact match (read: the header has to start with the exact
	 * same case sensitive string). The default value is <code>null</code>.
	 * 
	 * @return The additional HTTP header name.
	 */
	public String getUserAgentAdditionalHttpHeader() {
		return getString(USER_AGENT_ADDITIONAL_HEADER, null);
	}

	/**
	 * Returns the pattern to match additional headers to as defined in the
	 * renderer configuration. Default value is "".
	 *
	 * @return The User-Agent search pattern.
	 */
	public String getUserAgentAdditionalHttpHeaderSearch() {
		return getString(USER_AGENT_ADDITIONAL_SEARCH, "");
	}

	public String getUseSameExtension(String file) {
		String s = getString(USE_SAME_EXTENSION, null);

		if (s !is null) {
			s = file ~ "." ~ s;
		} else {
			s = file;
		}

		return s;
	}

	/**
	 * Returns true if SeekByTime is set to "true" or "exclusive", false otherwise.
	 * Default value is false.
	 *
	 * @return true if the renderer supports seek-by-time, false otherwise.
	 */
	public bool isSeekByTime() {
		return isSeekByTimeExclusive() || getBoolean(SEEK_BY_TIME, false);
	}

	/**
	 * Returns true if SeekByTime is set to "exclusive", false otherwise.
	 * Default value is false.
	 *
	 * @return true if the renderer supports seek-by-time exclusively
	 * (i.e. not in conjunction with seek-by-byte), false otherwise.
	 */
	public bool isSeekByTimeExclusive() {
		return getString(SEEK_BY_TIME, "").equalsIgnoreCase("exclusive");
	}

	public bool isMuxH264MpegTS() {
		bool muxCompatible = getBoolean(MUX_H264_WITH_MPEGTS, true);
		if (isMediaParserV2()) {
			muxCompatible = getFormatConfiguration().match(FormatConfiguration.MPEGTS, FormatConfiguration.H264, null) !is null;
		}

		if (Platform.isMac() && System.getProperty("os.version") !is null && System.getProperty("os.version").contains("10.4.")) {
			muxCompatible = false; // no tsMuxeR for 10.4 (yet?)
		}

		return muxCompatible;
	}

	public bool isDTSPlayable() {
		return isMuxDTSToMpeg() || (isWrapDTSIntoPCM() && isMuxLPCMToMpeg());
	}

	public bool isMuxDTSToMpeg() {
		if (isMediaParserV2()) {
			return getFormatConfiguration().isDTSSupported();
		}

		return getBoolean(MUX_DTS_TO_MPEG, false);
	}

	public bool isWrapDTSIntoPCM() {
		return getBoolean(WRAP_DTS_INTO_PCM, true);
	}

	public bool isLPCMPlayable() {
		return isMuxLPCMToMpeg();
	}

	public bool isMuxLPCMToMpeg() {
		if (isMediaParserV2()) {
			return getFormatConfiguration().isLPCMSupported();
		}

		return getBoolean(MUX_LPCM_TO_MPEG, true);
	}

	public bool isMpeg2Supported() {
		if (isMediaParserV2()) {
			return getFormatConfiguration().isMpeg2Supported();
		}

		return isPS3();
	}

	/**
	 * Returns the codec to use for video transcoding for this renderer as
	 * defined in the renderer configuration. Default value is "MPEGPSAC3".
	 *
	 * @return The codec name.
	 */
	public String getVideoTranscode() {
		return getString(TRANSCODE_VIDEO, MPEGPSAC3);
	}

	/**
	 * Returns the codec to use for audio transcoding for this renderer as
	 * defined in the renderer configuration. Default value is "LPCM".
	 *
	 * @return The codec name.
	 */
	public String getAudioTranscode() {
		return getString(TRANSCODE_AUDIO, LPCM);
	}

	/**
	 * Returns whether or not to use the default DVD buffer size for this
	 * renderer as defined in the renderer configuration. Default is false.
	 *
	 * @return True if the default size should be used.
	 */
	public bool isDefaultVBVSize() {
		return getBoolean(DEFAULT_VBV_BUFSIZE, false);
	}

	/**
	 * Returns the maximum bitrate (in megabits-per-second) supported by the media renderer as defined
	 * in the renderer configuration. The default value is <code>null</code>.
	 *
	 * @return The bitrate.
	 */
	deprecated
	// TODO this should return an integer and the units should be bits-per-second
	public String getMaxVideoBitrate() {
		return getString(MAX_VIDEO_BITRATE, null);
	}

	/**
	 * Returns the override settings for MEncoder quality settings in PMS as
	 * defined in the renderer configuration. The default value is "".
	 *
	 * @return The MEncoder quality settings.
	 */
	public String getCustomMencoderQualitySettings() {
		return getString(CUSTOM_MENCODER_QUALITY_SETTINGS, "");
	}

	/**
	 * Returns the override settings for MEncoder custom options in PMS as
	 * defined in the renderer configuration. The default value is "".
	 *
	 * @return The MEncoder custom options.
	 */
	public String getCustomMencoderOptions() {
		return getString(CUSTOM_MENCODER_OPTIONS, "");
	}

	/**
	 * Returns the maximum video width supported by the renderer as defined in
	 * the renderer configuration. The default value 0 means unlimited.
	 *
	 * @return The maximum video width.
	 */
	public int getMaxVideoWidth() {
		// FIXME why is this 1920 if the default value is 0 (unlimited)?
		// XXX we should also require width and height to both be 0 or both be > 0
		return getInt(MAX_VIDEO_WIDTH, 1920);
	}

	/**
	 * Returns the maximum video height supported by the renderer as defined
	 * in the renderer configuration. The default value 0 means unlimited.
	 *
	 * @return The maximum video height.
	 */
	public int getMaxVideoHeight() {
		// FIXME why is this 1080 if the default value is 0 (unlimited)?
		// XXX we should also require width and height to both be 0 or both be > 0
		return getInt(MAX_VIDEO_HEIGHT, 1080);
	}

	/**
	 * Returns <code>true</code> if the renderer has a maximum supported width
	 * or height, <code>false</code> otherwise.
	 *
	 * @return bool indicating whether the renderer may need videos to be resized.
	 */
	public bool isVideoRescale() {
		return getMaxVideoWidth() > 0 && getMaxVideoHeight() > 0;
	}

	public bool isDLNAOrgPNUsed() {
		return getBoolean(DLNA_ORGPN_USE, true);
	}

	/**
	 * Returns the comma separated list of file extensions that are forced to
	 * be transcoded and never streamed, as defined in the renderer
	 * configuration. Default value is "".
	 *
	 * @return The file extensions.
	 */
	public String getTranscodedExtensions() {
		return getString(TRANSCODE_EXT, "");
	}

	/**
	 * Returns the comma separated list of file extensions that are forced to
	 * be streamed and never transcoded, as defined in the renderer
	 * configuration. Default value is "".
	 *
	 * @return The file extensions.
	 */
	public String getStreamedExtensions() {
		return getString(STREAM_EXT, "");
	}

	/**
	 * Returns the size to report back to the renderer when transcoding media
	 * as defined in the renderer configuration. Default value is 0.
	 * 
	 * @return The size to report.
	 */
	public long getTranscodedSize() {
		return getLong(TRANSCODED_SIZE, 0);
	}

	/**
	 * Some devices (e.g. Samsung) recognize a custom HTTP header for retrieving
	 * the contents of a subtitles file. This method will return the name of that
	 * custom HTTP header, or "" if no such header exists. Default value is "".
	 *
	 * @return The name of the custom HTTP header.
	 */
	public String getSubtitleHttpHeader() {
		return getString(SUBTITLE_HTTP_HEADER, "");
	}

	private int getInt(String key, int def) {
		try {
			return configuration.getInt(key, def);
		} catch (ConversionException e) {
			return def;
		}
	}

	private long getLong(String key, int def) {
		try {
			return configuration.getLong(key, def);
		} catch (ConversionException e) {
			return def;
		}
	}

	private bool getBoolean(String key, bool def) {
		try {
			return configuration.getBoolean(key, def);
		} catch (ConversionException e) {
			return def;
		}
	}

	/**
     * Return the <code>String</code> value for a given configuration key if the
     * value is non-blank (i.e. not null, not an empty string, not all whitespace).
     * Otherwise return the supplied default value.
     * The value is returned with leading and trailing whitespace removed in both cases.
     * @param key The key to look up.
     * @param def The default value to return when no valid key value can be found.
     * @return The value configured for the key.
     */
    private String getString(String key, String def) {
		return ConfigurationUtil.getNonBlankConfigurationString(configuration, key, def);
    }

	public String toString() {
		return getRendererName();
	}

	public bool isMediaParserV2() {
		return getBoolean(MEDIAPARSERV2, false) && LibMediaInfoParser.isValid();
	}

	public bool isMediaParserV2ThumbnailGeneration() {
		return getBoolean(MEDIAPARSERV2_THUMB, false) && LibMediaInfoParser.isValid();
	}

	public bool isForceJPGThumbnails() {
		return (getBoolean(FORCE_JPG_THUMBNAILS, false) && LibMediaInfoParser.isValid()) || isBRAVIA();
	}

	public bool isShowAudioMetadata() {
		return getBoolean(SHOW_AUDIO_METADATA, true);
	}

	public bool isShowSubMetadata() {
		return getBoolean(SHOW_SUB_METADATA, true);
	}

	public bool isDLNATreeHack() {
		return getBoolean(DLNA_TREE_HACK, false) && LibMediaInfoParser.isValid();
	}

	/**
	 * Returns whether or not to omit sending a content length header when the
	 * length is unknown, as defined in the renderer configuration. Default
	 * value is false.
	 * <p>
	 * Some renderers are particular about the "Content-Length" headers in
	 * requests (e.g. Sony blu-ray players). By default, PMS will send a
	 * "Content-Length" that refers to the total media size, even if the exact
	 * length is unknown.
	 *
	 * @return True if sending the content length header should be omitted.
	 */
	public bool isChunkedTransfer() {
		return getBoolean(CHUNKED_TRANSFER, false);
	}

	/**
	 * Returns whether or not the renderer can handle the given format
	 * natively, based on its configuration in the renderer.conf. If it can
	 * handle a format natively, content can be streamed to the renderer. If
	 * not, content should be transcoded before sending it to the renderer.
	 *
	 * @param mediainfo The {@link DLNAMediaInfo} information parsed from the
	 * 				media file.
	 * @param format The {@link Format} to test compatibility for.
	 * @return True if the renderer natively supports the format, false
	 * 				otherwise.
	 */
	public bool isCompatible(DLNAMediaInfo mediainfo, Format format) {
		// Use the configured "Supported" lines in the renderer.conf
		// to see if any of them match the MediaInfo library
		if (isMediaParserV2() && mediainfo !is null && getFormatConfiguration().match(mediainfo) !is null) {
			return true;
		}

		if (format !is null) {
			String noTranscode = "";

			if (PMS.getConfiguration() !is null) {
				noTranscode = PMS.getConfiguration().getNoTranscode();
			}

			// Is the format among the ones to be streamed?
			return format.skip(noTranscode, getStreamedExtensions());
		} else {
			// Not natively supported.
			return false;
		}
	}
}
