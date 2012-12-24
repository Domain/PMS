module net.pms.configuration.FormatConfiguration;

import net.pms.dlna.DLNAMediaAudio;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.dlna.InputFile;
import net.pms.dlna.LibMediaInfoParser;
import net.pms.formats.Format;

import org.apache.commons.lang.StringUtils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.all;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

public class FormatConfiguration {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!FormatConfiguration();
	private ArrayList/*<SupportSpec>*/ supportSpecs;
	// Use old parser for JPEG files (MediaInfo does not support EXIF)
	private static const String[3] PARSER_V1_EXTENSIONS = [ ".jpg", ".jpe", ".jpeg" ];

	public static const String AAC = "aac";
	public static const String AC3 = "ac3";
	public static const String AIFF = "aiff";
	public static const String ALAC = "alac";
	public static const String APE = "ape";
	public static const String ATRAC = "atrac";
	public static const String AVI = "avi";
	public static const String BMP = "bmp";
	public static const String DIVX = "divx";
	public static const String DTS = "dts";
	public static const String DTSHD = "dtshd";
	public static const String DV = "dv";
	public static const String EAC3 = "eac3";
	public static const String FLAC = "flac";
	public static const String FLV = "flv";
	public static const String GIF = "gif";
	public static const String H264 = "h264";
	public static const String JPG = "jpg";
	public static const String LPCM = "lpcm";
	public static const String MATROSKA = "mkv";
	public static const String MI_GMC = "gmc";
	public static const String MI_QPEL = "qpel";
	public static const String MJPEG = "mjpeg";
	public static const String MLP = "mlp";
	public static const String MOV = "mov";
	public static const String MP3 = "mp3";
	public static const String MP4 = "mp4";
	public static const String MPA = "mpa";
	public static const String MPC = "mpc";
	public static const String MPEG1 = "mpeg1";
	public static const String MPEG2 = "mpeg2";
	public static const String MPEGPS = "mpegps";
	public static const String MPEGTS = "mpegts";
	public static const String OGG = "ogg";
	public static const String PNG = "png";
	public static const String RA = "ra";
	public static const String RM = "rm";
	public static const String SHORTEN = "shn";
	public static const String TIFF = "tiff";
	public static const String TRUEHD = "truehd";
	public static const String VC1 = "vc1";
	public static const String WAVPACK = "wavpack";
	public static const String WAV = "wav";
	public static const String WEBM = "WebM";
	public static const String WMA = "wma";
	public static const String WMV = "wmv";

	public static const String MIMETYPE_AUTO = "MIMETYPE_AUTO";
	public static const String und = "und";

	private class SupportSpec {
		private int iMaxBitrate = Integer.MAX_VALUE;
		private int iMaxFrequency = Integer.MAX_VALUE;
		private int iMaxNbChannels = Integer.MAX_VALUE;
		private int iMaxVideoHeight = Integer.MAX_VALUE;
		private int iMaxVideoWidth = Integer.MAX_VALUE;
		private Map/*<String, Pattern>*/ miExtras;
		private Pattern pAudioCodec;
		private Pattern pFormat;
		private Pattern pVideoCodec;
		private String audioCodec;
		private String format;
		private String line;
		private String maxBitrate;
		private String maxFrequency;
		private String maxNbChannels;
		private String maxVideoHeight;
		private String maxVideoWidth;
		private String mimeType;
		private String videoCodec;

		this() {
			this.mimeType = MIMETYPE_AUTO;
		}

		bool isValid() {
			if (StringUtils.isBlank(format)) { // required
				LOGGER.warn("No format supplied");
				return false;
			} else {
				try {
					pFormat = Pattern.compile(format);
				} catch (PatternSyntaxException pse) {
					LOGGER.error("Error parsing format: " ~ format, pse);
					return false;
				}
			}

			if (videoCodec !is null) {
				try {
					pVideoCodec = Pattern.compile(videoCodec);
				} catch (PatternSyntaxException pse) {
					LOGGER.error("Error parsing video codec: " ~ videoCodec, pse);
					return false;
				}
			}

			if (audioCodec !is null) {
				try {
					pAudioCodec = Pattern.compile(audioCodec);
				} catch (PatternSyntaxException pse) {
					LOGGER.error("Error parsing audio codec: " ~ audioCodec, pse);
					return false;
				}
			}

			if (maxNbChannels !is null) {
				try {
					iMaxNbChannels = Integer.parseInt(maxNbChannels);
				} catch (NumberFormatException nfe) {
					LOGGER.error("Error parsing number of channels: " ~ maxNbChannels, nfe);
					return false;
				}
			}

			if (maxFrequency !is null) {
				try {
					iMaxFrequency = Integer.parseInt(maxFrequency);
				} catch (NumberFormatException nfe) {
					LOGGER.error("Error parsing maximum frequency: " ~ maxFrequency, nfe);
					return false;
				}
			}

			if (maxBitrate !is null) {
				try {
					iMaxBitrate = Integer.parseInt(maxBitrate);
				} catch (NumberFormatException nfe) {
					LOGGER.error("Error parsing maximum bitrate: " ~ maxBitrate, nfe);
					return false;
				}
			}

			if (maxVideoWidth !is null) {
				try {
					iMaxVideoWidth = Integer.parseInt(maxVideoWidth);
				} catch (Exception nfe) {
					LOGGER.error("Error parsing maximum video width: " ~ maxVideoWidth, nfe);
					return false;
				}
			}

			if (maxVideoHeight !is null) {
				try {
					iMaxVideoHeight = Integer.parseInt(maxVideoHeight);
				} catch (NumberFormatException nfe) {
					LOGGER.error("Error parsing maximum video height: " ~ maxVideoHeight, nfe);
					return false;
				}
			}

			return true;
		}

		public bool match(String container, String videoCodec, String audioCodec) {
			return match(container, videoCodec, audioCodec, 0, 0, 0, 0, 0, null);
		}

		public bool match(
			String format,
			String videoCodec,
			String audioCodec,
			int nbAudioChannels,
			int frequency,
			int bitrate,
			int videoWidth,
			int videoHeight,
			Map/*<String, String>*/ extras
		) {
			bool matched = false;

			if (format !is null && !(matched = pFormat.matcher(format).matches())) {
				return false;
			}

			if (matched && videoCodec !is null && pVideoCodec !is null && !(matched = pVideoCodec.matcher(videoCodec).matches())) {
				return false;
			}

			if (matched && audioCodec !is null && pAudioCodec !is null && !(matched = pAudioCodec.matcher(audioCodec).matches())) {
				return false;
			}

			if (matched && nbAudioChannels > 0 && iMaxNbChannels > 0 && nbAudioChannels > iMaxNbChannels) {
				return false;
			}

			if (matched && frequency > 0 && iMaxFrequency > 0 && frequency > iMaxFrequency) {
				return false;
			}

			if (matched && bitrate > 0 && iMaxBitrate > 0 && bitrate > iMaxBitrate) {
				return false;
			}

			if (matched && videoWidth > 0 && iMaxVideoWidth > 0 && videoWidth > iMaxVideoWidth) {
				return false;
			}

			if (matched && videoHeight > 0 && iMaxVideoHeight > 0 && videoHeight > iMaxVideoHeight) {
				return false;
			}

			if (matched && extras !is null && miExtras !is null) {
				Iterator/*<String>*/ keyIt = extras.keySet().iterator();

				while (keyIt.hasNext()) {
					String key = keyIt.next();
					String value = extras.get(key);

					if (matched && key.equals(MI_QPEL) && miExtras.get(MI_QPEL) !is null) {
						matched = miExtras.get(MI_QPEL).matcher(value).matches();
					} else if (matched && key.equals(MI_GMC) && miExtras.get(MI_GMC) !is null) {
						matched = miExtras.get(MI_GMC).matcher(value).matches();
					}
				}
			}

			return matched;
		}
	}

	public this(List/*<?>*/ lines) {
		supportSpecs = new ArrayList/*<SupportSpec>*/();

		foreach (Object line ; lines) {
			if (line !is null) {
				SupportSpec supportSpec = parseSupportLine(line.toString());

				if (supportSpec.isValid()) {
					supportSpecs.add(supportSpec);
				} else {
					LOGGER.warn("Invalid configuration line: " ~ line);
				}
			}
		}
	}

	public void parse(DLNAMediaInfo media, InputFile file, Format ext, int type) {
		bool forceV1 = false;

		if (file.getFile() !is null) {
			String fName = file.getFile().getName().toLowerCase();

			foreach (String e ; PARSER_V1_EXTENSIONS) {
				if (fName.endsWith(e)) {
					forceV1 = true;
					break;
				}
			}

			if (forceV1) {
				// XXX this path generates thumbnails
				media.parse(file, ext, type, false);
			} else {
				// XXX this path doesn't generate thumbnails
				LibMediaInfoParser.parse(media, file, type);
			}
		} else {
			media.parse(file, ext, type, false);
		}
	}

	public bool isFormatSupported(String container) {
		return match(container, null, null) !is null;
	}

	public bool isDTSSupported() {
		return match(MPEGPS, null, DTS) !is null || match(MPEGTS, null, DTS) !is null;
	}

	public bool isLPCMSupported() {
		return match(MPEGPS, null, LPCM) !is null || match(MPEGTS, null, LPCM) !is null;
	}

	public bool isMpeg2Supported() {
		return match(MPEGPS, MPEG2, null) !is null || match(MPEGTS, MPEG2, null) !is null;
	}

	public String getPrimaryVideoTranscoder() {
		foreach (SupportSpec supportSpec ; supportSpecs) {
			if (supportSpec.match(MPEGPS, MPEG2, AC3)) {
				return MPEGPS;
			}

			if (supportSpec.match(MPEGTS, MPEG2, AC3)) {
				return MPEGTS;
			}

			if (supportSpec.match(WMV, WMV, WMA)) {
				return WMV;
			}
		}

		return null;
	}

	/**
	 * Match media information to audio codecs supported by the renderer
	 * and return its MIME-type if the match is successful. Returns null if
	 * the media is not natively supported by the renderer, which means it
	 * has to be transcoded.
	 * @param media The MediaInfo metadata
	 * @return The MIME type or null if no match was found.
	 */
	public String match(DLNAMediaInfo media) {
		if (media.getFirstAudioTrack() is null) {
			// no sound
			return match(
				media.getContainer(),
				media.getCodecV(),
				null,
				0,
				0,
				media.getBitrate(),
				media.getWidth(),
				media.getHeight(),
				media.getExtras()
			);
		} else {
			String finalMimeType = null;

			foreach (DLNAMediaAudio audio ; media.getAudioTracksList()) {
				String mimeType = match(
					media.getContainer(),
					media.getCodecV(),
					audio.getCodecA(),
					audio.getAudioProperties().getNumberOfChannels(),
					audio.getSampleRate(),
					media.getBitrate(),
					media.getWidth(),
					media.getHeight(),
					media.getExtras()
				);

				finalMimeType = mimeType;

				if (mimeType is null) { // if at least one audio track is not compatible, the file must be transcoded.
					return null;
				}
			}

			return finalMimeType;
		}
	}

	public String match(String container, String videoCodec, String audioCodec) {
		return match(
			container,
			videoCodec,
			audioCodec,
			0,
			0,
			0,
			0,
			0,
			null
		);
	}

	public String match(
		String container,
		String videoCodec,
		String audioCodec,
		int nbAudioChannels,
		int frequency,
		int bitrate,
		int videoWidth,
		int videoHeight,
		Map/*<String,
		String>*/ extras
	) {
		String matchedMimeType = null;

		foreach (SupportSpec supportSpec ; supportSpecs) {
			if (supportSpec.match(
				container,
				videoCodec,
				audioCodec,
				nbAudioChannels,
				frequency,
				bitrate,
				videoWidth,
				videoHeight,
				extras
			)) {
				matchedMimeType = supportSpec.mimeType;
				break;
			}
		}

		return matchedMimeType;
	}

	private SupportSpec parseSupportLine(String line) {
		StringTokenizer st = new StringTokenizer(line, "\t ");
		SupportSpec supportSpec = new SupportSpec();

		while (st.hasMoreTokens()) {
			String token = st.nextToken();

			if (token.startsWith("f:")) {
				supportSpec.format = token.substring(2).trim();
			} else if (token.startsWith("v:")) {
				supportSpec.videoCodec = token.substring(2).trim();
			} else if (token.startsWith("a:")) {
				supportSpec.audioCodec = token.substring(2).trim();
			} else if (token.startsWith("n:")) {
				supportSpec.maxNbChannels = token.substring(2).trim();
			} else if (token.startsWith("s:")) {
				supportSpec.maxFrequency = token.substring(2).trim();
			} else if (token.startsWith("w:")) {
				supportSpec.maxVideoWidth = token.substring(2).trim();
			} else if (token.startsWith("h:")) {
				supportSpec.maxVideoHeight = token.substring(2).trim();
			} else if (token.startsWith("m:")) {
				supportSpec.mimeType = token.substring(2).trim();
			} else if (token.startsWith("b:")) {
				supportSpec.maxBitrate = token.substring(2).trim();
			} else if (token.contains(":")) {
				// extra MediaInfo stuff
				if (supportSpec.miExtras is null) {
					supportSpec.miExtras = new HashMap<String, Pattern>();
				}

				String key = token.substring(0, token.indexOf(":"));
				String value = token.substring(token.indexOf(":") + 1);
				supportSpec.miExtras.put(key, Pattern.compile(value));
			}
		}

		return supportSpec;
	}
}
