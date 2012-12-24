module net.pms.dlna.LibMediaInfoParser;

import net.pms.configuration.FormatConfiguration;
import net.pms.formats.v2.SubtitleType;

import org.apache.commons.codec.binary.Base64;
import org.apache.commons.lang.StringUtils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.util.StringTokenizer;

public class LibMediaInfoParser {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!LibMediaInfoParser();
	private static MediaInfo MI;
	private static Base64 base64;

	static this() {
		MI = new MediaInfo();

		if (MI.isValid()) {
			MI.Option("Complete", "1");
			MI.Option("Language", "raw");
		}

		base64 = new Base64();
	}

	public static bool isValid() {
		return MI.isValid();
	}

	public static void close() {
		try {
			MI.finalize();
		} catch (Throwable e) {
			LOGGER._debug("Caught exception", e);
		}
	}

	public synchronized static void parse(DLNAMediaInfo media, InputFile inputFile, int type) {
		File file = inputFile.getFile();

		if (!media.isMediaparsed() && file !is null && MI.isValid() && MI.Open(file.getAbsolutePath()) > 0) {
			try {
				String info = MI.Inform();
				MediaInfo.StreamKind streamType = MediaInfo.StreamKind.General;
				DLNAMediaAudio currentAudioTrack = new DLNAMediaAudio();
				bool audioPrepped = false;
				DLNAMediaSubtitle currentSubTrack = new DLNAMediaSubtitle();
				bool subPrepped = false;

				if (StringUtils.isNotBlank(info)) {
					media.setSize(file.length());
					StringTokenizer st = new StringTokenizer(info, "\n\r");

					while (st.hasMoreTokens()) {
						String line = st.nextToken().trim();

						if (line.opEquals("Video") || line.startsWith("Video #")) {
							streamType = MediaInfo.StreamKind.Video;
						} else if (line.opEquals("Audio") || line.startsWith("Audio #")) {
							if (audioPrepped) {
								addAudio(currentAudioTrack, media);
								currentAudioTrack = new DLNAMediaAudio();
							}
							audioPrepped = true;
							streamType = MediaInfo.StreamKind.Audio;
						} else if (line.opEquals("Text") || line.startsWith("Text #")) {
							if (subPrepped) {
								addSub(currentSubTrack, media);
								currentSubTrack = new DLNAMediaSubtitle();
							}
							subPrepped = true;
							streamType = MediaInfo.StreamKind.Text;
						} else if (line.opEquals("Menu") || line.startsWith("Menu #")) {
							streamType = MediaInfo.StreamKind.Menu;
						} else if (line.opEquals("Chapters")) {
							streamType = MediaInfo.StreamKind.Chapters;
						}

						int point = line.indexOf(":");

						if (point > -1) {
							String key = line.substring(0, point).trim();
							String ovalue = line.substring(point + 1).trim();
							String value = ovalue.toLowerCase();

							if (key.opEquals("Format") || key.startsWith("Format_Version") || key.startsWith("Format_Profile")) {
								if (streamType == MediaInfo.StreamKind.Text) {
									// first attempt to detect subtitle track format
									currentSubTrack.setType(SubtitleType.valueOfLibMediaInfoCodec(value));
								} else {
									getFormat(streamType, media, currentAudioTrack, value, file);
								}
							} else if (key.opEquals("Duration/String1") && streamType == MediaInfo.StreamKind.General) {
								media.setDuration(getDuration(value));
							} else if (key.opEquals("Codec_Settings_QPel") && streamType == MediaInfo.StreamKind.Video) {
								media.putExtra(FormatConfiguration.MI_QPEL, value);
							} else if (key.opEquals("Codec_Settings_GMC") && streamType == MediaInfo.StreamKind.Video) {
								media.putExtra(FormatConfiguration.MI_GMC, value);
							} else if (key.opEquals("MuxingMode") && streamType == MediaInfo.StreamKind.Video) {
								media.setMuxingMode(ovalue);
							} else if (key.opEquals("CodecID")) {
								if (streamType == MediaInfo.StreamKind.Text) {
									// second attempt to detect subtitle track format (CodecID usually is more accurate)
									currentSubTrack.setType(SubtitleType.valueOfLibMediaInfoCodec(value));
								} else {
									getFormat(streamType, media, currentAudioTrack, value, file);
								}
							} else if (key.opEquals("Language/String")) {
								if (streamType == MediaInfo.StreamKind.Audio) {
									currentAudioTrack.setLang(getLang(value));
								} else if (streamType == MediaInfo.StreamKind.Text) {
									currentSubTrack.setLang(getLang(value));
								}
							} else if (key.opEquals("Title")) {
								if (streamType == MediaInfo.StreamKind.Audio) {
									currentAudioTrack.setFlavor(getFlavor(value));
								} else if (streamType == MediaInfo.StreamKind.Text) {
									currentSubTrack.setFlavor(getFlavor(value));
								}
							} else if (key.opEquals("Width")) {
								media.setWidth(getPixelValue(value));
							} else if (key.opEquals("Encryption") && !media.isEncrypted()) {
								media.setEncrypted("encrypted".opEquals(value));
							} else if (key.opEquals("Height")) {
								media.setHeight(getPixelValue(value));
							} else if (key.opEquals("FrameRate")) {
								media.setFrameRate(getFPSValue(value));
							} else if (key.opEquals("FrameRateMode")) {
								media.setFrameRateMode(getFrameRateModeValue(value));
							} else if (key.opEquals("OverallBitRate")) {
								if (streamType == MediaInfo.StreamKind.General) {
									media.setBitrate(getBitrate(value));
								}
							} else if (key.opEquals("Channel(s)")) {
								if (streamType == MediaInfo.StreamKind.Audio) {
									currentAudioTrack.getAudioProperties().setNumberOfChannels(value);
								}
                            } else if (key.opEquals("BitRate")) {
                                if (streamType == MediaInfo.StreamKind.Audio) {
                                    currentAudioTrack.setBitRate(getBitrate(value));
                                }
							} else if (key.opEquals("SamplingRate")) {
								if (streamType == MediaInfo.StreamKind.Audio) {
									currentAudioTrack.setSampleFrequency(getSampleFrequency(value));
								}
							} else if (key.opEquals("ID/String")) {
								// Special check for OGM: MediaInfo reports specific Audio/Subs IDs (0xn) while mencoder does not
								if (value.contains("(0x") && !FormatConfiguration.OGG.opEquals(media.getContainer())) {
									if (streamType == MediaInfo.StreamKind.Audio) {
										currentAudioTrack.setId(getSpecificID(value));
									} else if (streamType == MediaInfo.StreamKind.Text) {
										currentSubTrack.setId(getSpecificID(value));
									}
								} else {
									if (streamType == MediaInfo.StreamKind.Audio) {
										currentAudioTrack.setId(media.getAudioTracksList().size());
									} else if (streamType == MediaInfo.StreamKind.Text) {
										currentSubTrack.setId(media.getSubtitleTracksList().size());
									}
								}
							} else if (key.opEquals("Cover_Data") && streamType == MediaInfo.StreamKind.General) {
								media.setThumb(getCover(ovalue));
							} else if (key.opEquals("Track") && streamType == MediaInfo.StreamKind.General) {
								currentAudioTrack.setSongname(ovalue);
							} else if (key.opEquals("Album") && streamType == MediaInfo.StreamKind.General) {
								currentAudioTrack.setAlbum(ovalue);
							} else if (key.opEquals("Performer") && streamType == MediaInfo.StreamKind.General) {
								currentAudioTrack.setArtist(ovalue);
							} else if (key.opEquals("Genre") && streamType == MediaInfo.StreamKind.General) {
								currentAudioTrack.setGenre(ovalue);
							} else if (key.opEquals("Recorded_Date") && streamType == MediaInfo.StreamKind.General) {
								try {
									currentAudioTrack.setYear(Integer.parseInt(value));
								} catch (NumberFormatException nfe) {
									LOGGER._debug("Could not parse year \"" ~ value ~ "\"");
								}
							} else if (key.opEquals("Track/Position") && streamType == MediaInfo.StreamKind.General) {
								try {
									currentAudioTrack.setTrack(Integer.parseInt(value));
								} catch (NumberFormatException nfe) {
									LOGGER._debug("Could not parse track \"" ~ value ~ "\"");
								}
							} else if (key.opEquals("Resolution") && streamType == MediaInfo.StreamKind.Audio) {
								try {
									currentAudioTrack.setBitsperSample(Integer.parseInt(value));
								} catch (NumberFormatException nfe) {
									LOGGER._debug("Could not parse bits per sample \"" ~ value ~ "\"");
								}
							} else if (key.opEquals("Video_Delay") && streamType == MediaInfo.StreamKind.Audio) {
								try {
									currentAudioTrack.getAudioProperties().setAudioDelay(value);
								} catch (NumberFormatException nfe) {
									LOGGER._debug("Could not parse delay \"" ~ value ~ "\"");
								}
							}
						}
					}
				}

				if (audioPrepped) {
					addAudio(currentAudioTrack, media);
				}

				if (subPrepped) {
					addSub(currentSubTrack, media);
				}

				media.finalize(type, inputFile);
			} catch (Exception e) {
				LOGGER.error("Error in MediaInfo parsing:", e);
			} finally {
				MI.Close();
				if (media.getContainer() is null) {
					media.setContainer(DLNAMediaLang.UND);
				}

				if (media.getCodecV() is null) {
					media.setCodecV(DLNAMediaLang.UND);
				}

				media.setMediaparsed(true);
			}
		}
	}

	public static void addAudio(DLNAMediaAudio currentAudioTrack, DLNAMediaInfo media) {
		if (currentAudioTrack.getLang() is null) {
			currentAudioTrack.setLang(DLNAMediaLang.UND);
		}

		if (currentAudioTrack.getCodecA() is null) {
			currentAudioTrack.setCodecA(DLNAMediaLang.UND);
		}

		media.getAudioTracksList().add(currentAudioTrack);
	}

	public static void addSub(DLNAMediaSubtitle currentSubTrack, DLNAMediaInfo media) {
		if (currentSubTrack.getType() == SubtitleType.UNSUPPORTED) {
			return;
		}

		if (currentSubTrack.getLang() is null) {
			currentSubTrack.setLang(DLNAMediaLang.UND);
		}

		media.getSubtitleTracksList().add(currentSubTrack);
	}

	deprecated
	// FIXME this is obsolete (replaced by the private method below) and isn't called from anywhere outside this class
	public static void getFormat(MediaInfo.StreamKind streamType, DLNAMediaInfo media, DLNAMediaAudio audio, String value) {
		getFormat(streamType, media, audio, value, null);
	}

	private static void getFormat(MediaInfo.StreamKind streamType, DLNAMediaInfo media, DLNAMediaAudio audio, String value, File file) {
		String format = null;

		if (value.opEquals("matroska")) {
			format = FormatConfiguration.MATROSKA;
		} else if (value.opEquals("avi") || value.opEquals("opendml")) {
			format = FormatConfiguration.AVI;
		} else if (value.startsWith("flash")) {
			format = FormatConfiguration.FLV;
		} else if (value.toLowerCase().opEquals("webm")) {
			format = FormatConfiguration.WEBM;
		} else if (value.opEquals("qt") || value.opEquals("quicktime")) {
			format = FormatConfiguration.MOV;
		} else if (value.opEquals("isom") || value.startsWith("mp4") || value.opEquals("20") || value.opEquals("m4v") || value.startsWith("mpeg-4")) {
			format = FormatConfiguration.MP4;
		} else if (value.contains("mpeg-ps")) {
			format = FormatConfiguration.MPEGPS;
		} else if (value.contains("mpeg-ts") || value.opEquals("bdav")) {
			format = FormatConfiguration.MPEGTS;
		} else if (value.contains("aiff")) {
			format = FormatConfiguration.AIFF;
		} else if (value.contains("ogg")) {
			format = FormatConfiguration.OGG;
		} else if (value.contains("realmedia") || value.startsWith("rv") || value.startsWith("cook")) {
			format = FormatConfiguration.RM;
		} else if (value.contains("windows media") || value.opEquals("wmv1") || value.opEquals("wmv2") || value.opEquals("wmv7") || value.opEquals("wmv8")) {
			format = FormatConfiguration.WMV;
		} else if (value.contains("mjpg") || value.contains("m-jpeg")) {
			format = FormatConfiguration.MJPEG;
		} else if (value.startsWith("avc") || value.contains("h264")) {
			format = FormatConfiguration.H264;
		} else if (value.contains("xvid")) {
			format = FormatConfiguration.MP4;
		} else if (value.contains("mjpg") || value.contains("m-jpeg")) {
			format = FormatConfiguration.MJPEG;
		} else if (value.contains("div") || value.contains("dx")) {
			format = FormatConfiguration.DIVX;
		} else if (value.matches("(?i)(dv)|(cdv.?)|(dc25)|(dcap)|(dvc.?)|(dvs.?)|(dvrs)|(dv25)|(dv50)|(dvan)|(dvh.?)|(dvis)|(dvl.?)|(dvnm)|(dvp.?)|(mdvf)|(pdvc)|(r411)|(r420)|(sdcc)|(sl25)|(sl50)|(sldv)")) {
			format = FormatConfiguration.DV;
		} else if (value.contains("mpeg video")) {
			format = FormatConfiguration.MPEG2;
		} else if (value.opEquals("vc-1") || value.opEquals("vc1") || value.opEquals("wvc1") || value.opEquals("wmv3") || value.opEquals("wmv9") || value.opEquals("wmva")) {
			format = FormatConfiguration.VC1;
		} else if (value.opEquals("version 1")) {
			if (media.getCodecV() !is null && media.getCodecV().opEquals(FormatConfiguration.MPEG2) && audio.getCodecA() is null) {
				format = FormatConfiguration.MPEG1;
			}
		} else if (value.opEquals("layer 3")) {
			if (audio.getCodecA() !is null && audio.getCodecA().opEquals(FormatConfiguration.MPA)) {
				format = FormatConfiguration.MP3;
				// special case:
				if (media.getContainer() !is null && media.getContainer().opEquals(FormatConfiguration.MPA)) {
					media.setContainer(FormatConfiguration.MP3);
				}
			}
		} else if (value.opEquals("ma")) {
			if (audio.getCodecA() !is null && audio.getCodecA().opEquals(FormatConfiguration.DTS)) {
				format = FormatConfiguration.DTSHD;
			}
		} else if (value.opEquals("vorbis") || value.opEquals("a_vorbis")) {
			format = FormatConfiguration.OGG;
		} else if (value.opEquals("ac-3") || value.opEquals("a_ac3") || value.opEquals("2000")) {
			format = FormatConfiguration.AC3;
		} else if (value.opEquals("e-ac-3")) {
			format = FormatConfiguration.EAC3;
		} else if (value.contains("truehd")) {
			format = FormatConfiguration.TRUEHD;
		} else if (value.opEquals("55") || value.opEquals("a_mpeg/l3")) {
			format = FormatConfiguration.MP3;
		} else if (value.opEquals("m4a") || value.opEquals("40") || value.opEquals("a_aac") || value.opEquals("aac")) {
			format = FormatConfiguration.AAC;
		} else if (value.opEquals("pcm") || (value.opEquals("1") && (audio.getCodecA() is null || !audio.getCodecA().opEquals(FormatConfiguration.DTS)))) {
			format = FormatConfiguration.LPCM;
		} else if (value.opEquals("alac")) {
			format = FormatConfiguration.ALAC;
		} else if (value.opEquals("wave")) {
			format = FormatConfiguration.WAV;
		} else if (value.opEquals("shorten")) {
			format = FormatConfiguration.SHORTEN;
		} else if (value.opEquals("dts") || value.opEquals("a_dts") || value.opEquals("8")) {
			format = FormatConfiguration.DTS;
		} else if (value.opEquals("mpeg audio")) {
			format = FormatConfiguration.MPA;
		} else if (value.opEquals("161") || value.startsWith("wma")) {
			format = FormatConfiguration.WMA;
			if (media.getCodecV() is null) {
				media.setContainer(FormatConfiguration.WMA);
			}
		} else if (value.opEquals("flac")) {
			format = FormatConfiguration.FLAC;
		} else if (value.opEquals("monkey's audio")) {
			format = FormatConfiguration.APE;
		} else if (value.contains("musepack")) {
			format = FormatConfiguration.MPC;
		} else if (value.contains("wavpack")) {
			format = FormatConfiguration.WAVPACK;
		} else if (value.contains("mlp")) {
			format = FormatConfiguration.MLP;
		} else if (value.contains("atrac3")) {
			format = FormatConfiguration.ATRAC;
			if (media.getCodecV() is null) {
				media.setContainer(FormatConfiguration.ATRAC);
			}
		} else if (value.opEquals("jpeg")) {
			format = FormatConfiguration.JPG;
		} else if (value.opEquals("png")) {
			format = FormatConfiguration.PNG;
		} else if (value.opEquals("gif")) {
			format = FormatConfiguration.GIF;
		} else if (value.opEquals("bitmap")) {
			format = FormatConfiguration.BMP;
		} else if (value.opEquals("tiff")) {
			format = FormatConfiguration.TIFF;
		}

		if (format !is null) {
			if (streamType == MediaInfo.StreamKind.General) {
				media.setContainer(format);
			} else if (streamType == MediaInfo.StreamKind.Video) {
				media.setCodecV(format);
			} else if (streamType == MediaInfo.StreamKind.Audio) {
				audio.setCodecA(format);
			}
		}
	}

	public static int getPixelValue(String value) {
		if (value.indexOf("pixel") > -1) {
			value = value.substring(0, value.indexOf("pixel"));
		}

		value = value.trim();

		// Value can look like "512 / 512" at this point
		if (value.contains("/")) {
			value = value.substring(0, value.indexOf("/")).trim();
		}

		int pixels = Integer.parseInt(value);
		return pixels;
	}

	public static int getBitrate(String value) {
		if (value.contains("/")) {
			value = value.substring(0, value.indexOf("/")).trim();
		}

        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException ex) {
            LOGGER.info("Unknown bitrate detected. Returning 0.");
            return 0;
        }
	}

	public static int getSpecificID(String value) {
		if (value.indexOf("(0x") > -1) {
			value = value.substring(0, value.indexOf("(0x"));
		}

		value = value.trim();
		int id = Integer.parseInt(value);
		return id;
	}

	public static String getSampleFrequency(String value) {
		// some tracks show several values like "48000 / 48000 / 24000" for HE-AAC
		// store only the first value
		if (value.indexOf("/") > -1) {
			value = value.substring(0, value.indexOf("/"));
		}

		if (value.indexOf("khz") > -1) {
			value = value.substring(0, value.indexOf("khz"));
		}

		value = value.trim();
		return value;
	}

	public static String getFPSValue(String value) {
		if (value.indexOf("fps") > -1) {
			value = value.substring(0, value.indexOf("fps"));
		}

		value = value.trim();
		return value;
	}

	public static String getFrameRateModeValue(String value) {
		if (value.indexOf("/") > -1) {
			value = value.substring(0, value.indexOf("/"));
		}

		value = value.trim();
		return value;
	}

	public static String getLang(String value) {
		if (value.indexOf("(") > -1) {
			value = value.substring(0, value.indexOf("("));
		}

		if (value.indexOf("/") > -1) {
			value = value.substring(0, value.indexOf("/"));
		}

		value = value.trim();
		return value;
	}

	public static String getFlavor(String value) {
		value = value.trim();
		return value;
	}

	private static double getDuration(String value) {
		int h = 0, m = 0, s = 0;
		StringTokenizer st = new StringTokenizer(value, " ");

		while (st.hasMoreTokens()) {
			String token = st.nextToken();
			int hl = token.indexOf("h");

			if (hl > -1) {
				h = Integer.parseInt(token.substring(0, hl).trim());
			}

			int mnl = token.indexOf("mn");

			if (mnl > -1) {
				m = Integer.parseInt(token.substring(0, mnl).trim());
			}

			int msl = token.indexOf("ms");

			if (msl == -1) {
				// Only check if ms was not found
				int sl = token.indexOf("s");

				if (sl > -1) {
					s = Integer.parseInt(token.substring(0, sl).trim());
				}
			}
		}

		return (h * 3600) + (m * 60) + s;
	}

	public static byte[] getCover(String based64Value) {
		try {
			if (base64 !is null) {
				return base64.decode(based64Value.getBytes());
			}
		} catch (Exception e) {
			LOGGER.error("Error in decoding thumbnail data", e);
		}

		return null;
	}
}
