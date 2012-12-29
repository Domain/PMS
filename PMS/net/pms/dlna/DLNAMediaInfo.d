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
module net.pms.dlna.DLNAMediaInfo;

import com.sun.jna.Platform;

//import java.awt.Color;
//import java.awt.Font;
//import java.awt.Graphics;
//import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.lang.exceptions;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.ListIterator;
import java.util.Locale;
import java.util.Map;
//import java.util.NoSuchElementException;
import java.util.StringTokenizer;

//import javax.imageio.ImageIO;
//
//import net.coobird.thumbnailator.tasks.UnsupportedFormatException;
//import net.coobird.thumbnailator.Thumbnails.Builder;
//import net.coobird.thumbnailator.Thumbnails;

import net.pms.PMS;
import net.pms.configuration.RendererConfiguration;
import net.pms.formats.AudioAsVideo;
import net.pms.formats.Format;
import net.pms.formats.v2.SubtitleType;
import net.pms.io.OutputParams;
import net.pms.io.ProcessWrapperImpl;
import net.pms.network.HTTPResource;
import net.pms.util.AVCHeader;
import net.pms.util.CoverUtil;
import net.pms.util.FileUtil;
import net.pms.util.MpegUtil;
import net.pms.util.ProcessUtil;

import org.apache.commons.lang.StringUtils;
//import org.apache.sanselan.ImageInfo;
//import org.apache.sanselan.Sanselan;
//import org.apache.sanselan.common.IImageMetadata;
//import org.apache.sanselan.formats.jpeg.JpegImageMetadata;
//import org.apache.sanselan.formats.tiff.TiffField;
//import org.apache.sanselan.formats.tiff.constants.TiffConstants;

//import org.jaudiotagger.audio.AudioFile;
//import org.jaudiotagger.audio.AudioFileIO;
//import org.jaudiotagger.audio.AudioHeader;
//import org.jaudiotagger.tag.FieldKey;
//import org.jaudiotagger.tag.Tag;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This class keeps track of media file metadata scanned by the MediaInfo library.
 *
 * TODO: Change all instance variables to private. For backwards compatibility
 * with external plugin code the variables have all been marked as deprecated
 * instead of changed to private, but this will surely change in the future.
 * When everything has been changed to private, the deprecated note can be
 * removed.
 */
public class DLNAMediaInfo : Cloneable {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!DLNAMediaInfo();
	private static const String THUMBNAIL_DIRECTORY_NAME = "thumbs";

	public static const long ENDFILE_POS = 99999475712L;
	public static const long TRANS_SIZE = 100000000000L;

	private bool h264_parsed;

	// Stored in database
	private Double durationSec;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public int bitrate;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public int width;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public int height;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public long size;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String codecV;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String frameRate;

	private String frameRateMode;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String aspect;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public byte thumb[];

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String mimeType;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public int bitsPerPixel;

	private List/*<DLNAMediaAudio>*/ audioTracks = new ArrayList/*<DLNAMediaAudio>*/();
	private List/*<DLNAMediaSubtitle>*/ subtitleTracks = new ArrayList/*<DLNAMediaSubtitle>*/();

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String model;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public int exposure;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public int orientation;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public int iso;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String muxingMode;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String muxingModeAudio;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String container;

	/**
	 * @deprecated Use {@link #getH264AnnexB()} and {@link #setH264AnnexB(byte[])} to access this variable.
	 */
	deprecated
	public byte[] h264_annexB;

	/**
	 * Not stored in database.
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public bool mediaparsed;

	/**
	 * isMediaParserV2 related, used to manage thumbnail management separated
	 * from the main parsing process.
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public bool thumbready;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public int dvdtrack;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public bool secondaryFormatValid = true;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public bool parsing = false;

	private bool ffmpeg_failure;
	private bool ffmpeg_annexb_failure;
	private bool muxable;
	private Map/*<String, String>*/ extras;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public bool encrypted;

	public bool isMuxable(RendererConfiguration mediaRenderer) {
		// temporary fix: MediaInfo support will take care of this in the future

		// for now, http://ps3mediaserver.org/forum/viewtopic.php?f=11&t=6361&start=0
		if (mediaRenderer.isBRAVIA() && getCodecV() !is null && getCodecV().startsWith("mpeg2")) {
			muxable = true;
		}

		if (mediaRenderer.isBRAVIA() && getHeight() < 288) { // not supported for these small heights
			muxable = false;
		}

		return muxable;
	}

	public Map/*<String, String>*/ getExtras() {
		return extras;
	}

	public void putExtra(String key, String value) {
		if (extras is null) {
			extras = new HashMap/*<String, String>*/();
		}

		extras.put(key, value);
	}

	public String getExtrasAsString() {
		if (extras is null) {
			return null;
		}

		StringBuilder sb = new StringBuilder();

		foreach (Map.Entry/*<String, String>*/ entry ; extras.entrySet()) {
			sb.append(entry.getKey());
			sb.append("|");
			sb.append(entry.getValue());
			sb.append("|");
		}

		return sb.toString();
	}

	public void setExtrasAsString(String value) {
		if (value !is null) {
			StringTokenizer st = new StringTokenizer(value, "|");
			while (st.hasMoreTokens()) {
				try {
					putExtra(st.nextToken(), st.nextToken());
				} catch (NoSuchElementException nsee) {
					LOGGER._debug("Caught exception", nsee);
				}
			}
		}
	}

	public this() {
		setThumbready(true); // this class manages thumbnails by default with the parser_v1 method
	}

	public void generateThumbnail(InputFile input, Format ext, int type) {
		DLNAMediaInfo forThumbnail = new DLNAMediaInfo();
		forThumbnail.durationSec = durationSec;
		forThumbnail.parse(input, ext, type, true);
		setThumb(forThumbnail.getThumb());
	}

	private ProcessWrapperImpl getFFMpegThumbnail(InputFile media) {
		String[] args = new String[14];
		args[0] = getFfmpegPath();
		bool dvrms = media.getFile() !is null && media.getFile().getAbsolutePath().toLowerCase().endsWith("dvr-ms");

		if (dvrms && StringUtils.isNotBlank(PMS.getConfiguration().getFfmpegAlternativePath())) {
			args[0] = PMS.getConfiguration().getFfmpegAlternativePath();
		}

		args[1] = "-ss";
		args[2] = "" ~ PMS.getConfiguration().getThumbnailSeekPos();
		args[3] = "-i";

		if (media.getFile() !is null) {
			args[4] = ProcessUtil.getShortFileNameIfWideChars(media.getFile().getAbsolutePath());
		} else {
			args[4] = "-";
		}

		args[5] = "-an";
		args[6] = "-an";
		args[7] = "-s";
		args[8] = "320x180";
		args[9] = "-vframes";
		args[10] = "1";
		args[11] = "-f";
		args[12] = "image2";
		args[13] = "pipe:";

		// FIXME MPlayer should not be used if thumbnail generation is disabled (and it should be disabled in the GUI)
		if (!PMS.getConfiguration().isThumbnailGenerationEnabled() || (PMS.getConfiguration().isUseMplayerForVideoThumbs() && !dvrms)) {
			args[2] = "0";
			for (int i = 5; i <= 13; i++) {
				args[i] = "-an";
			}
		}

		OutputParams params = new OutputParams(PMS.getConfiguration());
		params.maxBufferSize = 1;
		params.stdin = media.getPush();
		params.noexitcheck = true; // not serious if anything happens during the thumbnailer

		// true: consume stderr on behalf of the caller i.e. parse()
		final ProcessWrapperImpl pw = new ProcessWrapperImpl(args, params, false, true);

		// FAILSAFE
		setParsing(true);
		Runnable r = dgRunnable( {
			try {
				Thread.sleep(10000);
				ffmpeg_failure = true;
			} catch (InterruptedException e) { }
			pw.stopProcess();
			setParsing(false);
		});

		Thread failsafe = new Thread(r, "FFMpeg Thumbnail Failsafe");
		failsafe.start();
		pw.runInSameThread();
		setParsing(false);
		return pw;
	}

	private ProcessWrapperImpl getMplayerThumbnail(InputFile media) {
		String args[] = new String[14];
		args[0] = PMS.getConfiguration().getMplayerPath();
		args[1] = "-ss";
		bool toolong = getDurationInSeconds() < PMS.getConfiguration().getThumbnailSeekPos();
		args[2] = "" ~ (toolong ? (getDurationInSeconds() / 2) : PMS.getConfiguration().getThumbnailSeekPos());
		args[3] = "-quiet";

		if (media.getFile() !is null) {
			args[4] = ProcessUtil.getShortFileNameIfWideChars(media.getFile().getAbsolutePath());
		} else {
			args[4] = "-";
		}

		args[5] = "-msglevel";
		args[6] = "all=4";
		args[7] = "-vf";
		args[8] = "scale=320:-2,expand=:180";
		args[9] = "-frames";
		args[10] = "1";
		args[11] = "-vo";
		String frameName = "" ~ media.hashCode();
		frameName = "mplayer_thumbs:subdirs=\"" ~ frameName ~ "\"";
		frameName = frameName.replace(',', '_');
		args[12] = "jpeg:outdir=" ~ frameName;
		args[13] = "-nosound";
		OutputParams params = new OutputParams(PMS.getConfiguration());
		params.workDir = PMS.getConfiguration().getTempFolder();
		params.maxBufferSize = 1;
		params.stdin = media.getPush();
		params.log = true;
		params.noexitcheck = true; // not serious if anything happens during the thumbnailer
		immutable ProcessWrapperImpl pw = new ProcessWrapperImpl(args, params);

		// FAILSAFE
		setParsing(true);
		Runnable r = dgRunnable( {
			try {
				Thread.sleep(3000);
				//mplayer_thumb_failure = true;
			} catch (InterruptedException e) { }
			pw.stopProcess();
			setParsing(false);
		});

		Thread failsafe = new Thread(r, "MPlayer Thumbnail Failsafe");
		failsafe.start();
		pw.runInSameThread();
		setParsing(false);
		return pw;
	}

	private String getFfmpegPath() {
		String value = PMS.getConfiguration().getFfmpegPath();

		if (value is null) {
			LOGGER.info("No ffmpeg - unable to thumbnail");
			throw new RuntimeException("No ffmpeg - unable to thumbnail");
		} else {
			return value;
		}
	}

	public void parse(InputFile inputFile, Format ext, int type, bool thumbOnly) {
		int i = 0;

		while (isParsing()) {
			if (i == 5) {
				setMediaparsed(true);
				break;
			}

			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) { }

			i++;
		}

		if (isMediaparsed()) {
			return;
		}

		if (inputFile !is null) {
			if (inputFile.getFile() !is null) {
				setSize(inputFile.getFile().length());
			} else {
				setSize(inputFile.getSize());
			}

			ProcessWrapperImpl pw = null;
			bool ffmpeg_parsing = true;

			if (type == Format.AUDIO || cast(AudioAsVideo)ext !is null) {
				ffmpeg_parsing = false;
				DLNAMediaAudio audio = new DLNAMediaAudio();

				if (inputFile.getFile() !is null) {
					try {
						AudioFile af = AudioFileIO.read(inputFile.getFile());
						AudioHeader ah = af.getAudioHeader();

						if (ah !is null && !thumbOnly) {
							int length = ah.getTrackLength();
							int rate = ah.getSampleRateAsNumber();

							if (ah.getEncodingType().toLowerCase().contains("flac 24")) {
								audio.setBitsperSample(24);
							}

							audio.setSampleFrequency(rate.toString());
							setDuration(cast(double) length);
							setBitrate(cast(int) ah.getBitRateAsNumber());
							audio.getAudioProperties().setNumberOfChannels(2);

							if (ah.getChannels() !is null && ah.getChannels().toLowerCase().contains("mono")) {
								audio.getAudioProperties().setNumberOfChannels(1);
							} else if (ah.getChannels() !is null && ah.getChannels().toLowerCase().contains("stereo")) {
								audio.getAudioProperties().setNumberOfChannels(2);
							} else if (ah.getChannels() !is null) {
								audio.getAudioProperties().setNumberOfChannels(Integer.parseInt(ah.getChannels()));
							}

							audio.setCodecA(ah.getEncodingType().toLowerCase());

							if (audio.getCodecA().contains("(windows media")) {
								audio.setCodecA(audio.getCodecA().substring(0, audio.getCodecA().indexOf("(windows media")).trim());
							}
						}

						Tag t = af.getTag();

						if (t !is null) {
							if (t.getArtworkList().size() > 0) {
								setThumb(t.getArtworkList().get(0).getBinaryData());
							} else {
								if (PMS.getConfiguration().getAudioThumbnailMethod() > 0) {
									setThumb(
										CoverUtil.get().getThumbnailFromArtistAlbum(
											PMS.getConfiguration().getAudioThumbnailMethod() == 1 ?
												CoverUtil.AUDIO_AMAZON :
												CoverUtil.AUDIO_DISCOGS,
											audio.getArtist(), audio.getAlbum()
										)
									);
								}
							}

							if (!thumbOnly) {
								audio.setAlbum(t.getFirst(FieldKey.ALBUM));
								audio.setArtist(t.getFirst(FieldKey.ARTIST));
								audio.setSongname(t.getFirst(FieldKey.TITLE));
								String y = t.getFirst(FieldKey.YEAR);

								try {
									if (y.length() > 4) {
										y = y.substring(0, 4);
									}
									audio.setYear(Integer.parseInt(((y !is null && y.length() > 0) ? y : "0")));
									y = t.getFirst(FieldKey.TRACK);
									audio.setTrack(Integer.parseInt(((y !is null && y.length() > 0) ? y : "1")));
									audio.setGenre(t.getFirst(FieldKey.GENRE));
								} catch (Throwable e) {
									LOGGER._debug("Error parsing unimportant metadata: " ~ e.getMessage());
								}
							}
						}
					} catch (Throwable e) {
						LOGGER._debug("Error parsing audio file: %s - %s", e.getMessage(), e.getCause() !is null ? e.getCause().getMessage() : "");
						ffmpeg_parsing = false;
					}

					if (audio.getSongname() is null || audio.getSongname().length() == 0) {
						audio.setSongname(inputFile.getFile().getName());
					}

					if (!ffmpeg_parsing) {
						getAudioTracksList().add(audio);
					}
				}
			}

			if (type == Format.IMAGE && inputFile.getFile() !is null) {
				try {
					ffmpeg_parsing = false;
					ImageInfo info = Sanselan.getImageInfo(inputFile.getFile());
					setWidth(info.getWidth());
					setHeight(info.getHeight());
					setBitsPerPixel(info.getBitsPerPixel());
					String formatName = info.getFormatName();

					if (formatName.startsWith("JPEG")) {
						setCodecV("jpg");
						IImageMetadata meta = Sanselan.getMetadata(inputFile.getFile());

						if (meta !is null && cast(JpegImageMetadata)meta !is null) {
							JpegImageMetadata jpegmeta = cast(JpegImageMetadata) meta;
							TiffField tf = jpegmeta.findEXIFValue(TiffConstants.EXIF_TAG_MODEL);

							if (tf !is null) {
								setModel(tf.getStringValue().trim());
							}

							tf = jpegmeta.findEXIFValue(TiffConstants.EXIF_TAG_EXPOSURE_TIME);
							if (tf !is null) {
								setExposure(cast(int) (1000 * tf.getDoubleValue()));
							}

							tf = jpegmeta.findEXIFValue(TiffConstants.EXIF_TAG_ORIENTATION);
							if (tf !is null) {
								setOrientation(tf.getIntValue());
							}

							tf = jpegmeta.findEXIFValue(TiffConstants.EXIF_TAG_ISO);
							if (tf !is null) {
								// Galaxy Nexus jpg pictures may contain multiple values, take the first
								int[] isoValues = tf.getIntArrayValue();
								setIso(isoValues[0]);
							}
						}
					} else if (formatName.startsWith("PNG")) {
						setCodecV("png");
					} else if (formatName.startsWith("GIF")) {
						setCodecV("gif");
					} else if (formatName.startsWith("TIF")) {
						setCodecV("tiff");
					}

					setContainer(getCodecV());
				} catch (Throwable e) {
					// ffmpeg_parsing = true;
					LOGGER.info("Error parsing image (%s) with Sanselan, switching to FFmpeg", inputFile.getFile().getAbsolutePath(), e);
				}
			}

			if (PMS.getConfiguration().getImageThumbnailsEnabled()) {
				try {
					File thumbDir = new File(PMS.getConfiguration().getTempFolder(), THUMBNAIL_DIRECTORY_NAME);

					LOGGER.trace("Generating thumbnail for: %s", inputFile.getFile().getAbsolutePath());

					if (!thumbDir.exists() && !thumbDir.mkdirs()) {
						LOGGER.warn("Could not create thumbnail directory: %s", thumbDir.getAbsolutePath());
					} else {
						File thumbFile = new File(thumbDir, inputFile.getFile().getName() ~ ".jpg");
						String thumbFilename = thumbFile.getAbsolutePath();

						LOGGER.trace("Creating (temporary) thumbnail: %s", thumbFilename);

						// Create the thumbnail image using the Thumbnailator library
						final Builder/*<File>*/ thumbnail = Thumbnails.of(inputFile.getFile());
						thumbnail.size(320, 180);
						thumbnail.outputFormat("jpg");
						thumbnail.outputQuality(1.0f);
						thumbnail.toFile(thumbFilename);

						File jpg = new File(thumbFilename);

						if (jpg.exists()) {
							InputStream _is = new FileInputStream(jpg);
							int sz = _is.available();

							if (sz > 0) {
								setThumb(new byte[sz]);
								_is.read(getThumb());
							}

							_is.close();

							if (!jpg._delete()) {
								jpg.deleteOnExit();
							}
						}
					}
				} catch (UnsupportedFormatException ufe) {
					LOGGER.warn("Can't create thumbnail for %s: %s", inputFile.getFile().getAbsolutePath(), ufe.getMessage());
				} catch (Exception e) {
					LOGGER.warn("Error generating thumbnail for: %s", inputFile.getFile().getAbsolutePath(), e);
				}
			}

			if (ffmpeg_parsing) {
				if (!thumbOnly || !PMS.getConfiguration().isUseMplayerForVideoThumbs()) {
					pw = getFFMpegThumbnail(inputFile);
				}

				String input = "-";
				bool dvrms = false;

				if (inputFile.getFile() !is null) {
					input = ProcessUtil.getShortFileNameIfWideChars(inputFile.getFile().getAbsolutePath());
					dvrms = inputFile.getFile().getAbsolutePath().toLowerCase().endsWith("dvr-ms");
				}

				if (!ffmpeg_failure && !thumbOnly) {
					if (input.opEquals("-")) {
						input = "pipe:";
					}

					bool matchs = false;
					ArrayList/*<String>*/ lines = cast(ArrayList/*<String>*/) pw.getResults();
					int langId = 0;
					int subId = 0;
					ListIterator/*<String>*/ FFmpegMetaData = lines.listIterator();

					foreach (String line ; lines) {
						FFmpegMetaData.next();
						line = line.trim();
						if (line.startsWith("Output")) {
							matchs = false;
						} else if (line.startsWith("Input")) {
							if (line.indexOf(input) > -1) {
								matchs = true;
								setContainer(line.substring(10, line.indexOf(",", 11)).trim());
							} else {
								matchs = false;
							}
						} else if (matchs) {
							if (line.indexOf("Duration") > -1) {
								StringTokenizer st = new StringTokenizer(line, ",");
								while (st.hasMoreTokens()) {
									String token = st.nextToken().trim();
									if (token.startsWith("Duration: ")) {
										String durationStr = token.substring(10);
										int l = durationStr.substring(durationStr.indexOf(".") + 1).length();
										if (l < 4) {
											durationStr = durationStr ~ "00".substring(0, 3 - l);
										}
										if (durationStr.indexOf("N/A") > -1) {
											setDuration(null);
										} else {
											setDuration(parseDurationString(durationStr));
										}

									} else if (token.startsWith("bitrate: ")) {
										String bitr = token.substring(9);
										int spacepos = bitr.indexOf(" ");
										if (spacepos > -1) {
											String value = bitr.substring(0, spacepos);
											String unit = bitr.substring(spacepos + 1);
											setBitrate(Integer.parseInt(value));
											if (unit.opEquals("kb/s")) {
												setBitrate(1024 * getBitrate());
											}
											if (unit.opEquals("mb/s")) {
												setBitrate(1048576 * getBitrate());
											}
										}
									}
								}
							} else if (line.indexOf("Audio:") > -1) {
								StringTokenizer st = new StringTokenizer(line, ",");
								int a = line.indexOf("(");
								int b = line.indexOf("):", a);
								DLNAMediaAudio audio = new DLNAMediaAudio();
								audio.setId(langId++);
								if (a > -1 && b > a) {
									audio.setLang(line.substring(a + 1, b));
								} else {
									audio.setLang(DLNAMediaLang.UND);
								}
								// Get TS IDs
								a = line.indexOf("[0x");
								b = line.indexOf("]", a);
								if (a > -1 && b > a + 3) {
									String idString = line.substring(a + 3, b);
									try {
										audio.setId(Integer.parseInt(idString, 16));
									} catch (NumberFormatException nfe) {
										LOGGER._debug("Error parsing Stream ID: " ~ idString);
									}
								}

								while (st.hasMoreTokens()) {
									String token = st.nextToken().trim();
									if (token.startsWith("Stream")) {
										audio.setCodecA(token.substring(token.indexOf("Audio: ") + 7));

									} else if (token.endsWith("Hz")) {
										audio.setSampleFrequency(token.substring(0, token.indexOf("Hz")).trim());
									} else if (token.opEquals("mono")) {
										audio.getAudioProperties().setNumberOfChannels(1);
									} else if (token.opEquals("stereo")) {
										audio.getAudioProperties().setNumberOfChannels(2);
									} else if (token.opEquals("5:1") || token.opEquals("5.1") || token.opEquals("6 channels")) {
										audio.getAudioProperties().setNumberOfChannels(6);
									} else if (token.opEquals("5 channels")) {
										audio.getAudioProperties().setNumberOfChannels(5);
									} else if (token.opEquals("4 channels")) {
										audio.getAudioProperties().setNumberOfChannels(4);
									} else if (token.opEquals("2 channels")) {
										audio.getAudioProperties().setNumberOfChannels(2);
									} else if (token.opEquals("s32")) {
										audio.setBitsperSample(32);
									} else if (token.opEquals("s24")) {
										audio.setBitsperSample(24);
									} else if (token.opEquals("s16")) {
										audio.setBitsperSample(16);
									}
								}
								int FFmpegMetaDataNr = FFmpegMetaData.nextIndex();
								if (FFmpegMetaDataNr > -1) line = lines.get(FFmpegMetaDataNr);
								if (line.indexOf("Metadata:") > -1) {
									FFmpegMetaDataNr = FFmpegMetaDataNr + 1;
									line = lines.get(FFmpegMetaDataNr);
									while (line.indexOf("      ") == 0) {
										if (line.toLowerCase().indexOf("title           :") > -1) {
											int aa = line.indexOf(": ");
											int bb = line.length();
											if (aa > -1 && bb > aa) {
												audio.setFlavor(line.substring(aa+2, bb));
												break;
											}
										} else {
											FFmpegMetaDataNr = FFmpegMetaDataNr + 1;
											line = lines.get(FFmpegMetaDataNr);
										}
									}
								}
								getAudioTracksList().add(audio);
							} else if (line.indexOf("Video:") > -1) {
								StringTokenizer st = new StringTokenizer(line, ",");
								while (st.hasMoreTokens()) {
									String token = st.nextToken().trim();
									if (token.startsWith("Stream")) {
										setCodecV(token.substring(token.indexOf("Video: ") + 7));
									} else if ((token.indexOf("tbc") > -1 || token.indexOf("tb(c)") > -1)) {
										// A/V sync issues with newest FFmpeg, due to the new tbr/tbn/tbc outputs
										// Priority to tb(c)
										String frameRateDoubleString = token.substring(0, token.indexOf("tb")).trim();
										try {
											if (!frameRateDoubleString.opEquals(getFrameRate())) {// tbc taken into account only if different than tbr
												Double frameRateDouble = Double.parseDouble(frameRateDoubleString);
												setFrameRate(String.format(Locale.ENGLISH, "%.2f", frameRateDouble / 2));
											}
										} catch (NumberFormatException nfe) {
											// Could happen if tbc is "1k" or something like that, no big deal
											LOGGER._debug("Could not parse frame rate \"" ~ frameRateDoubleString ~ "\"");
										}

									} else if ((token.indexOf("tbr") > -1 || token.indexOf("tb(r)") > -1) && getFrameRate() is null) {
										setFrameRate(token.substring(0, token.indexOf("tb")).trim());
									} else if ((token.indexOf("fps") > -1 || token.indexOf("fps(r)") > -1) && getFrameRate() is null) { // dvr-ms ?
										setFrameRate(token.substring(0, token.indexOf("fps")).trim());
									} else if (token.indexOf("x") > -1) {
										String resolution = token.trim();
										if (resolution.indexOf(" [") > -1) {
											resolution = resolution.substring(0, resolution.indexOf(" ["));
										}
										try {
											setWidth(Integer.parseInt(resolution.substring(0, resolution.indexOf("x"))));
										} catch (NumberFormatException nfe) {
											LOGGER._debug("Could not parse width from \"" ~ resolution.substring(0, resolution.indexOf("x")) ~ "\"");
										}
										try {
											setHeight(Integer.parseInt(resolution.substring(resolution.indexOf("x") + 1)));
										} catch (NumberFormatException nfe) {
											LOGGER._debug("Could not parse height from \"" ~ resolution.substring(resolution.indexOf("x") + 1) ~ "\"");
										}
									}
								}
							} else if (line.indexOf("Subtitle:") > -1 && !line.contains("tx3g")) {
								DLNAMediaSubtitle lang = new DLNAMediaSubtitle();
								lang.setType((line.contains("dvdsub") && Platform.isWindows() ? SubtitleType.VOBSUB : SubtitleType.UNKNOWN));
								int a = line.indexOf("(");
								int b = line.indexOf("):", a);
								if (a > -1 && b > a) {
									lang.setLang(line.substring(a + 1, b));
								} else {
									lang.setLang(DLNAMediaLang.UND);
								}

								lang.setId(subId++);
								int FFmpegMetaDataNr = FFmpegMetaData.nextIndex();

								if (FFmpegMetaDataNr > -1) {
									line = lines.get(FFmpegMetaDataNr);
								}

								if (line.indexOf("Metadata:") > -1) {
									FFmpegMetaDataNr = FFmpegMetaDataNr + 1;
									line = lines.get(FFmpegMetaDataNr);

									while (line.indexOf("      ") == 0) {
										if (line.toLowerCase().indexOf("title           :") > -1) {
											int aa = line.indexOf(": ");
											int bb = line.length();
											if (aa > -1 && bb > aa) {
												lang.setFlavor(line.substring(aa+2, bb));
												break;
											}
										} else {
											FFmpegMetaDataNr = FFmpegMetaDataNr + 1;
											line = lines.get(FFmpegMetaDataNr);
										}
									}
								}
								getSubtitleTracksList().add(lang);
							}
						}
					}
				}

				if (!thumbOnly && getContainer() !is null && inputFile.getFile() !is null && getContainer().opEquals("mpegts") && isH264() && getDurationInSeconds() == 0) {
					// let's do the parsing for getting the duration...
					try {
						int length = MpegUtil.getDurationFromMpeg(inputFile.getFile());
						if (length > 0) {
							setDuration(cast(double) length);
						}
					} catch (IOException e) {
						LOGGER.trace("Error retrieving length: " ~ e.getMessage());
					}
				}

				if (PMS.getConfiguration().isUseMplayerForVideoThumbs() && type == Format.VIDEO && !dvrms) {
					try {
						getMplayerThumbnail(inputFile);
						String frameName = "" ~ inputFile.hashCode();
						frameName = PMS.getConfiguration().getTempFolder() ~ "/mplayer_thumbs/" ~ frameName ~ "00000001/00000001.jpg";
						frameName = frameName.replace(',', '_');
						File jpg = new File(frameName);

						if (jpg.exists()) {
							InputStream _is = new FileInputStream(jpg);
							int sz = _is.available();

							if (sz > 0) {
								setThumb(new byte[sz]);
								_is.read(getThumb());
							}

							_is.close();

							if (!jpg._delete()) {
								jpg.deleteOnExit();
							}

							// Try and retry
							if (!jpg.getParentFile()._delete() && !jpg.getParentFile()._delete()) {
								LOGGER._debug("Failed to delete \"" ~ jpg.getParentFile().getAbsolutePath() ~ "\"");
							}
						}
					} catch (IOException e) {
						LOGGER._debug("Caught exception", e);
					}
				}

				if (type == Format.VIDEO && pw !is null && getThumb() is null) {
					InputStream _is;
					try {
						_is = pw.getInputStream(0);
						int sz = _is.available();
						if (sz > 0) {
							setThumb(new byte[sz]);
							_is.read(getThumb());
						}
						_is.close();

						if (sz > 0 && !java.awt.GraphicsEnvironment.isHeadless()) {
							BufferedImage image = ImageIO.read(new ByteArrayInputStream(getThumb()));
							if (image !is null) {
								Graphics g = image.getGraphics();
								g.setColor(Color.WHITE);
								g.setFont(new Font("Arial", Font.PLAIN, 14));
								int low = 0;
								if (getWidth() > 0) {
									if (getWidth() == 1920 || getWidth() == 1440) {
										g.drawString("1080p", 0, low += 18);
									} else if (getWidth() == 1280) {
										g.drawString("720p", 0, low += 18);
									}
								}
								ByteArrayOutputStream _out = new ByteArrayOutputStream();
								ImageIO.write(image, "jpeg", _out);
								setThumb(_out.toByteArray());
							}
						}
					} catch (IOException e) {
						LOGGER._debug("Error while decoding thumbnail: " ~ e.getMessage());
					}
				}
			}

			finalize(type, inputFile);
			setMediaparsed(true);
		}
	}

	public bool isH264() {
		return getCodecV() !is null && getCodecV().contains("264");
	}

	public int getFrameNumbers() {
		double fr = Double.parseDouble(getFrameRate());
		return cast(int) (getDurationInSeconds() * fr);
	}

	public void setDuration(Double d) {
		this.durationSec = d;
	}

	public Double getDuration() {
		return durationSec;
	}

	/**
	 *
	 * @return 0 if nothing is specified, otherwise the duration
	 */
	public double getDurationInSeconds() {
		return durationSec !is null ? durationSec : 0;
	}

	public String getDurationString() {
		return durationSec !is null ? getDurationString(durationSec) : null;
	}

	public static String getDurationString(double d) {
		int s = (cast(int) d) % 60;
		int h = cast(int) (d / 3600);
		int m = (cast(int) (d / 60)) % 60;
		return String.format("%02d:%02d:%02d.00", h, m, s);
	}

	public static Double parseDurationString(String duration) {
		if (duration is null) {
			return null;
		}

		StringTokenizer st = new StringTokenizer(duration, ":");

		try {
			int h = Integer.parseInt(st.nextToken());
			int m = Integer.parseInt(st.nextToken());
			double s = Double.parseDouble(st.nextToken());
			return h * 3600 + m * 60 + s;
		} catch (NumberFormatException nfe) {
			LOGGER._debug("Failed to parse duration \"" ~ duration ~ "\"");
		}

		return null;
	}

	public void finalize(int type, InputFile f) {
		String codecA = null;

		if (getFirstAudioTrack() !is null) {
			codecA = getFirstAudioTrack().getCodecA();
		}

		if (getContainer() !is null && getContainer().opEquals("avi")) {
			setMimeType(HTTPResource.AVI_TYPEMIME);
		} else if (getContainer() !is null && (getContainer().opEquals("asf") || getContainer().opEquals("wmv"))) {
			setMimeType(HTTPResource.WMV_TYPEMIME);
		} else if (getContainer() !is null && (getContainer().opEquals("matroska") || getContainer().opEquals("mkv"))) {
			setMimeType(HTTPResource.MATROSKA_TYPEMIME);
		} else if (getCodecV() !is null && getCodecV().opEquals("mjpeg")) {
			setMimeType(HTTPResource.JPEG_TYPEMIME);
		} else if ("png".opEquals(getCodecV()) || "png".opEquals(getContainer())) {
			setMimeType(HTTPResource.PNG_TYPEMIME);
		} else if ("gif".opEquals(getCodecV()) || "gif".opEquals(getContainer())) {
			setMimeType(HTTPResource.GIF_TYPEMIME);
		} else if (getCodecV() !is null && (getCodecV().opEquals("h264") || getCodecV().opEquals("h263") || getCodecV().toLowerCase().opEquals("mpeg4") || getCodecV().toLowerCase().opEquals("mp4"))) {
			setMimeType(HTTPResource.MP4_TYPEMIME);
		} else if (getCodecV() !is null && (getCodecV().indexOf("mpeg") > -1 || getCodecV().indexOf("mpg") > -1)) {
			setMimeType(HTTPResource.MPEG_TYPEMIME);
		} else if (getCodecV() is null && codecA !is null && codecA.contains("mp3")) {
			setMimeType(HTTPResource.AUDIO_MP3_TYPEMIME);
		} else if (getCodecV() is null && codecA !is null && codecA.contains("aac")) {
			setMimeType(HTTPResource.AUDIO_MP4_TYPEMIME);
		} else if (getCodecV() is null && codecA !is null && codecA.contains("flac")) {
			setMimeType(HTTPResource.AUDIO_FLAC_TYPEMIME);
		} else if (getCodecV() is null && codecA !is null && codecA.contains("vorbis")) {
			setMimeType(HTTPResource.AUDIO_OGG_TYPEMIME);
		} else if (getCodecV() is null && codecA !is null && (codecA.contains("asf") || codecA.startsWith("wm"))) {
			setMimeType(HTTPResource.AUDIO_WMA_TYPEMIME);
		} else if (getCodecV() is null && codecA !is null && (codecA.startsWith("pcm") || codecA.contains("wav"))) {
			setMimeType(HTTPResource.AUDIO_WAV_TYPEMIME);
		} else {
			setMimeType(HTTPResource.getDefaultMimeType(type));
		}

		if (getFirstAudioTrack() is null || !(type == Format.AUDIO && getFirstAudioTrack().getBitsperSample() == 24 && getFirstAudioTrack().getSampleRate() > 48000)) {
			setSecondaryFormatValid(false);
		}

		// Check for external subs here
		if (f.getFile() !is null && type == Format.VIDEO && PMS.getConfiguration().isAutoloadSubtitles()) {
			FileUtil.doesSubtitlesExists(f.getFile(), this);
		}
	}

	public bool isVideoPS3Compatible(InputFile f) {
		if (!h264_parsed) {
			if (getCodecV() !is null && (getCodecV().opEquals("h264") || getCodecV().startsWith("mpeg2"))) { // what about VC1 ?
				muxable = true;
				if (getCodecV().opEquals("h264") && getContainer() !is null && (getContainer().opEquals("matroska") || getContainer().opEquals("mkv") || getContainer().opEquals("mov") || getContainer().opEquals("mp4"))) { // containers without h264_annexB
					byte headers[][] = getAnnexBFrameHeader(f);
					if (ffmpeg_annexb_failure) {
						LOGGER.info("Fatal error when retrieving AVC informations !");
					}

					if (headers !is null) {
						setH264AnnexB(headers[1]);
						if (getH264AnnexB() !is null) {
							int skip = 5;
							if (getH264AnnexB()[2] == 1) {
								skip = 4;
							}
							byte header[] = new byte[getH264AnnexB().length - skip];
							System.arraycopy(getH264AnnexB(), skip, header, 0, header.length);
							AVCHeader avcHeader = new AVCHeader(header);
							avcHeader.parse();
							LOGGER.trace("H264 file: " ~ f.getFilename() ~ ": Profile: " ~ avcHeader.getProfile() ~ " / level: " ~ avcHeader.getLevel() ~ " / ref frames: " ~ avcHeader.getRef_frames());
							muxable = true;

							// Check if file is compliant with Level4.1
							if (avcHeader.getLevel() >= 41 && getWidth() > 0 && getHeight() > 0) {
								int maxref = cast(int) Math.floor(8388608 / (getWidth() * getHeight()));
								if (avcHeader.getRef_frames() > maxref) {
									muxable = false;
								}
							}
							if (!muxable) {
								LOGGER._debug("H264 file: " ~ f.getFilename() ~ " is not ps3 compatible !");
							}
						} else {
							muxable = false;
						}
					} else {
						muxable = false;
					}
				}
			}

			h264_parsed = true;
		}

		return muxable;
	}

	public bool isMuxable(String filename, String codecA) {
		return codecA !is null && (codecA.startsWith("dts") || codecA.opEquals("dca"));
	}

	public bool isLossless(String codecA) {
		return codecA !is null && (codecA.contains("pcm") || codecA.startsWith("dts") || codecA.opEquals("dca") || codecA.contains("flac")) && !codecA.contains("pcm_u8") && !codecA.contains("pcm_s8");
	}

	public String toString() {
		String s = "container: " ~ getContainer() ~ " / bitrate: " ~ getBitrate() ~ " / size: " ~ getSize() ~ " / codecV: " ~ getCodecV() ~ " / duration: " ~ getDurationString() ~ " / width: " ~ getWidth() ~ " / height: " ~ getHeight() ~ " / frameRate: " ~ getFrameRate() ~ " / thumb size : " ~ (getThumb() !is null ? getThumb().length : 0) ~ " / muxingMode: " ~ getMuxingMode();

		foreach (DLNAMediaAudio audio ; getAudioTracksList()) {
			s ~= "\n\taudio: id=" ~ audio.getId() ~ " / lang: " ~ audio.getLang() ~ " / flavor: " ~ audio.getFlavor() ~ " / codec: " ~ audio.getCodecA() ~ " / sf:" ~ audio.getSampleFrequency() ~ " / na: " ~ (audio.getAudioProperties() !is null ? audio.getAudioProperties().getNumberOfChannels() : "-") ~ " / bs: " ~ audio.getBitsperSample();
			if (audio.getArtist() !is null) {
				s ~= " / " ~ audio.getArtist() ~ "|" ~ audio.getAlbum() ~ "|" ~ audio.getSongname() ~ "|" ~ audio.getYear() + "|" ~ audio.getTrack();
			}
		}

		foreach (DLNAMediaSubtitle sub ; getSubtitleTracksList()) {
			s ~= "\n\tsub: id=" ~ sub.getId() ~ " / lang: " ~ sub.getLang() ~ " / flavor: " ~ sub.getFlavor() ~ " / type: " ~ (sub.getType() !is null ? sub.getType().toString() : "null");
		}

		return s;
	}

	public InputStream getThumbnailInputStream() {
		return new ByteArrayInputStream(getThumb());
	}

	public String getValidFps(bool ratios) {
		String validFrameRate = null;

		if (getFrameRate() !is null && getFrameRate().length() > 0) {
			try {
				double fr = Double.parseDouble(getFrameRate().replace(',', '.'));

				if (fr >= 14.99 && fr < 15.1) {
					validFrameRate = "15";
				} else if (fr > 23.9 && fr < 23.99) {
					validFrameRate = ratios ? "24000/1001" : "23.976";
				} else if (fr > 23.99 && fr < 24.1) {
					validFrameRate = "24";
				} else if (fr >= 24.99 && fr < 25.1) {
					validFrameRate = "25";
				} else if (fr > 29.9 && fr < 29.99) {
					validFrameRate = ratios ? "30000/1001" : "29.97";
				} else if (fr >= 29.99 && fr < 30.1) {
					validFrameRate = "30";
				} else if (fr > 47.9 && fr < 47.99) {
					validFrameRate = ratios ? "48000/1001" : "47.952";
				} else if (fr > 49.9 && fr < 50.1) {
					validFrameRate = "50";
				} else if (fr > 59.9 && fr < 59.99) {
					validFrameRate = ratios ? "60000/1001" : "59.94";
				} else if (fr >= 59.99 && fr < 60.1) {
					validFrameRate = "60";
				}
			} catch (NumberFormatException nfe) {
				LOGGER.error(null, nfe);
			}
		}

		return validFrameRate;
	}

	public DLNAMediaAudio getFirstAudioTrack() {
		if (getAudioTracksList().size() > 0) {
			return getAudioTracksList().get(0);
		}
		return null;
	}

	public String getValidAspect(bool ratios) {
		String a = null;

		if (getAspect() !is null) {
			double ar = Double.parseDouble(getAspect());

			if (ar > 1.7 && ar < 1.8) {
				a = ratios ? "16/9" : "1.777777777777777";
			}

			if (ar > 1.3 && ar < 1.4) {
				a = ratios ? "4/3" : "1.333333333333333";
			}
		}

		return a;
	}

	public String getResolution() {
		if (getWidth() > 0 && getHeight() > 0) {
			return getWidth() ~ "x" ~ getHeight();
		}

		return null;
	}

	public int getRealVideoBitrate() {
		if (getBitrate() > 0) {
			return (getBitrate() / 8);
		}

		int realBitrate = 10000000;

		if (getDurationInSeconds() != 0) {
			realBitrate = cast(int) (getSize() / getDurationInSeconds());
		}

		return realBitrate;
	}

	public bool isHDVideo() {
		return (getWidth() > 1200 || getHeight() > 700);
	}

	public bool isMpegTS() {
		return getContainer() !is null && getContainer().opEquals("mpegts");
	}

	public byte[][] getAnnexBFrameHeader(InputFile f) {
		String[] cmdArray = new String[14];
		cmdArray[0] = PMS.getConfiguration().getFfmpegPath();
		cmdArray[1] = "-i";

		if (f.getPush() is null && f.getFilename() !is null) {
			cmdArray[2] = f.getFilename();
		} else {
			cmdArray[2] = "-";
		}

		cmdArray[3] = "-vframes";
		cmdArray[4] = "1";
		cmdArray[5] = "-vcodec";
		cmdArray[6] = "copy";
		cmdArray[7] = "-f";
		cmdArray[8] = "h264";
		cmdArray[9] = "-vbsf";
		cmdArray[10] = "h264_mp4toannexb";
		cmdArray[11] = "-an";
		cmdArray[12] = "-y";
		cmdArray[13] = "pipe:";

		byte[][] returnData = new byte[2][];
		OutputParams params = new OutputParams(PMS.getConfiguration());
		params.maxBufferSize = 1;
		params.stdin = f.getPush();

		immutable ProcessWrapperImpl pw = new ProcessWrapperImpl(cmdArray, params);

		Runnable r = dgRunnable( {
			try {
				Thread.sleep(3000);
				ffmpeg_annexb_failure = true;
			} catch (InterruptedException e) { }
			pw.stopProcess();
		});

		Thread failsafe = new Thread(r, "FFMpeg AnnexB Frame Header Failsafe");
		failsafe.start();
		pw.runInSameThread();

		if (ffmpeg_annexb_failure) {
			return null;
		}

		InputStream _is = null;
		ByteArrayOutputStream baot = new ByteArrayOutputStream();

		try {
			_is = pw.getInputStream(0);
			byte b[] = new byte[4096];
			int n = -1;

			while ((n = _is.read(b)) > 0) {
				baot.write(b, 0, n);
			}

			byte data[] = baot.toByteArray();
			baot.close();
			returnData[0] = data;
			_is.close();
			int kf = 0;

			for (int i = 3; i < data.length; i++) {
				if (data[i - 3] == 1 && (data[i - 2] & 37) == 37 && (data[i - 1] & -120) == -120) {
					kf = i - 2;
					break;
				}
			}

			int st = 0;
			bool found = false;

			if (kf > 0) {
				for (int i = kf; i >= 5; i--) {
					if (data[i - 5] == 0 && data[i - 4] == 0 && data[i - 3] == 0 && (data[i - 2] & 1) == 1 && (data[i - 1] & 39) == 39) {
						st = i - 5;
						found = true;
						break;
					}
				}
			}

			if (found) {
				byte header[] = new byte[kf - st];
				System.arraycopy(data, st, header, 0, kf - st);
				returnData[1] = header;
			}
		} catch (IOException e) {
			LOGGER._debug("Caught exception", e);
		}

		return returnData;
	}

	override
	protected Object clone() {
		Object cloned = super.clone();

		if (cast(DLNAMediaInfo)cloned !is null) {
			DLNAMediaInfo mediaCloned = (cast(DLNAMediaInfo) cloned);
			mediaCloned.setAudioTracksList(new ArrayList/*<DLNAMediaAudio>*/());

			foreach (DLNAMediaAudio audio ; getAudioTracksList()) {
				mediaCloned.getAudioTracksList().add(cast(DLNAMediaAudio) audio.clone());
			}

			mediaCloned.setSubtitleTracksList(new ArrayList/*<DLNAMediaSubtitle>*/());

			foreach (DLNAMediaSubtitle sub ; getSubtitleTracksList()) {
				mediaCloned.getSubtitleTracksList().add(cast(DLNAMediaSubtitle) sub.clone());
			}
		}

		return cloned;
	}

	/**
	 * @return the bitrate
	 * @since 1.50.0
	 */
	public int getBitrate() {
		return bitrate;
	}

	/**
	 * @param bitrate the bitrate to set
	 * @since 1.50.0
	 */
	public void setBitrate(int bitrate) {
		this.bitrate = bitrate;
	}

	/**
	 * @return the width
	 * @since 1.50.0
	 */
	public int getWidth() {
		return width;
	}

	/**
	 * @param width the width to set
	 * @since 1.50.0
	 */
	public void setWidth(int width) {
		this.width = width;
	}

	/**
	 * @return the height
	 * @since 1.50.0
	 */
	public int getHeight() {
		return height;
	}

	/**
	 * @param height the height to set
	 * @since 1.50.0
	 */
	public void setHeight(int height) {
		this.height = height;
	}

	/**
	 * @return the size
	 * @since 1.50.0
	 */
	public long getSize() {
		return size;
	}

	/**
	 * @param size the size to set
	 * @since 1.50.0
	 */
	public void setSize(long size) {
		this.size = size;
	}

	/**
	 * @return the codecV
	 * @since 1.50.0
	 */
	public String getCodecV() {
		return codecV;
	}

	/**
	 * @param codecV the codecV to set
	 * @since 1.50.0
	 */
	public void setCodecV(String codecV) {
		this.codecV = codecV;
	}

	/**
	 * @return the frameRate
	 * @since 1.50.0
	 */
	public String getFrameRate() {
		return frameRate;
	}

	/**
	 * @param frameRate the frameRate to set
	 * @since 1.50.0
	 */
	public void setFrameRate(String frameRate) {
		this.frameRate = frameRate;
	}

	/**
	 * @return the frameRateMode
	 * @since 1.55.0
	 */
	public String getFrameRateMode() {
		return frameRateMode;
	}

	/**
	 * @param frameRateMode the frameRateMode to set
	 * @since 1.55.0
	 */
	public void setFrameRateMode(String frameRateMode) {
		this.frameRateMode = frameRateMode;
	}

	/**
	 * @return the aspect
	 * @since 1.50.0
	 */
	public String getAspect() {
		return aspect;
	}

	/**
	 * @param aspect the aspect to set
	 * @since 1.50.0
	 */
	public void setAspect(String aspect) {
		this.aspect = aspect;
	}

	/**
	 * @return the thumb
	 * @since 1.50.0
	 */
	public byte[] getThumb() {
		return thumb;
	}

	/**
	 * @param thumb the thumb to set
	 * @since 1.50.0
	 */
	public void setThumb(byte[] thumb) {
		this.thumb = thumb;
	}

	/**
	 * @return the mimeType
	 * @since 1.50.0
	 */
	public String getMimeType() {
		return mimeType;
	}

	/**
	 * @param mimeType the mimeType to set
	 * @since 1.50.0
	 */
	public void setMimeType(String mimeType) {
		this.mimeType = mimeType;
	}

	/**
	 * @return the bitsPerPixel
	 * @since 1.50.0
	 */
	public int getBitsPerPixel() {
		return bitsPerPixel;
	}

	/**
	 * @param bitsPerPixel the bitsPerPixel to set
	 * @since 1.50.0
	 */
	public void setBitsPerPixel(int bitsPerPixel) {
		this.bitsPerPixel = bitsPerPixel;
	}

	/**
	 * @return the audioTracks
	 * @since 1.60.0
	 */
	public List/*<DLNAMediaAudio>*/ getAudioTracksList() {
		return audioTracks;
	}

	/**
	 * @return the audioTracks
	 * @deprecated use getAudioTracksList() instead
	 */
	deprecated
	public ArrayList/*<DLNAMediaAudio>*/ getAudioCodes() {
		if (cast(ArrayList)audioTracks !is null ) {
			return cast(ArrayList/*<DLNAMediaAudio>*/) audioTracks;
		} else {
			return new ArrayList/*<DLNAMediaAudio>*/();
		}
	}

	/**
	 * @param audioTracks the audioTracks to set
	 * @since 1.60.0
	 */
	public void setAudioTracksList(List/*<DLNAMediaAudio>*/ audioTracks) {
		this.audioTracks = audioTracks;
	}

	/**
	 * @param audioTracks the audioTracks to set
	 * @deprecated use setAudioTracksList(ArrayList<DLNAMediaAudio> audioTracks) instead
	 */
	deprecated
	public void setAudioCodes(List/*<DLNAMediaAudio>*/ audioTracks) {
		setAudioTracksList(audioTracks);
	}

	/**
	 * @return the subtitleTracks
	 * @since 1.60.0
	 */
	public List/*<DLNAMediaSubtitle>*/ getSubtitleTracksList() {
		return subtitleTracks;
	}

	/**
	 * @return the subtitleTracks
	 * @deprecated use getSubtitleTracksList() instead
	 */
	deprecated
	public ArrayList/*<DLNAMediaSubtitle>*/ getSubtitlesCodes() {
		if (cast(ArrayList)subtitleTracks !is null ) {
			return cast(ArrayList/*<DLNAMediaSubtitle>*/) subtitleTracks;
		} else {
			return new ArrayList/*<DLNAMediaSubtitle>*/();
		}
	}

	/**
	 * @param subtitleTracks the subtitleTracks to set
	 * @since 1.60.0
	 */
	public void setSubtitleTracksList(List/*<DLNAMediaSubtitle>*/ subtitleTracks) {
		this.subtitleTracks = subtitleTracks;
	}

	/**
	 * @param subtitleTracks the subtitleTracks to set
	 * @deprecated use setSubtitleTracksList(ArrayList<DLNAMediaSubtitle> subtitleTracks) instead
	 */
	deprecated
	public void setSubtitlesCodes(List/*<DLNAMediaSubtitle>*/ subtitleTracks) {
		setSubtitleTracksList(subtitleTracks);
	}

	/**
	 * @return the model
	 * @since 1.50.0
	 */
	public String getModel() {
		return model;
	}

	/**
	 * @param model the model to set
	 * @since 1.50.0
	 */
	public void setModel(String model) {
		this.model = model;
	}

	/**
	 * @return the exposure
	 * @since 1.50.0
	 */
	public int getExposure() {
		return exposure;
	}

	/**
	 * @param exposure the exposure to set
	 * @since 1.50.0
	 */
	public void setExposure(int exposure) {
		this.exposure = exposure;
	}

	/**
	 * @return the orientation
	 * @since 1.50.0
	 */
	public int getOrientation() {
		return orientation;
	}

	/**
	 * @param orientation the orientation to set
	 * @since 1.50.0
	 */
	public void setOrientation(int orientation) {
		this.orientation = orientation;
	}

	/**
	 * @return the iso
	 * @since 1.50.0
	 */
	public int getIso() {
		return iso;
	}

	/**
	 * @param iso the iso to set
	 * @since 1.50.0
	 */
	public void setIso(int iso) {
		this.iso = iso;
	}

	/**
	 * @return the muxingMode
	 * @since 1.50.0
	 */
	public String getMuxingMode() {
		return muxingMode;
	}

	/**
	 * @param muxingMode the muxingMode to set
	 * @since 1.50.0
	 */
	public void setMuxingMode(String muxingMode) {
		this.muxingMode = muxingMode;
	}

	/**
	 * @return the muxingModeAudio
	 * @since 1.50.0
	 */
	public String getMuxingModeAudio() {
		return muxingModeAudio;
	}

	/**
	 * @param muxingModeAudio the muxingModeAudio to set
	 * @since 1.50.0
	 */
	public void setMuxingModeAudio(String muxingModeAudio) {
		this.muxingModeAudio = muxingModeAudio;
	}

	/**
	 * @return the container
	 * @since 1.50.0
	 */
	public String getContainer() {
		return container;
	}

	/**
	 * @param container the container to set
	 * @since 1.50.0
	 */
	public void setContainer(String container) {
		this.container = container;
	}

	/**
	 * @return the h264_annexB
	 * @since 1.50.0
	 */
	public byte[] getH264AnnexB() {
		return h264_annexB;
	}

	/**
	 * @param h264AnnexB the h264_annexB to set
	 * @since 1.50.0
	 */
	public void setH264AnnexB(byte[] h264AnnexB) {
		this.h264_annexB = h264AnnexB;
	}

	/**
	 * @return the mediaparsed
	 * @since 1.50.0
	 */
	public bool isMediaparsed() {
		return mediaparsed;
	}

	/**
	 * @param mediaparsed the mediaparsed to set
	 * @since 1.50.0
	 */
	public void setMediaparsed(bool mediaparsed) {
		this.mediaparsed = mediaparsed;
	}

	/**
	 * @return the thumbready
	 * @since 1.50.0
	 */
	public bool isThumbready() {
		return thumbready;
	}

	/**
	 * @param thumbready the thumbready to set
	 * @since 1.50.0
	 */
	public void setThumbready(bool thumbready) {
		this.thumbready = thumbready;
	}

	/**
	 * @return the dvdtrack
	 * @since 1.50.0
	 */
	public int getDvdtrack() {
		return dvdtrack;
	}

	/**
	 * @param dvdtrack the dvdtrack to set
	 * @since 1.50.0
	 */
	public void setDvdtrack(int dvdtrack) {
		this.dvdtrack = dvdtrack;
	}

	/**
	 * @return the secondaryFormatValid
	 * @since 1.50.0
	 */
	public bool isSecondaryFormatValid() {
		return secondaryFormatValid;
	}

	/**
	 * @param secondaryFormatValid the secondaryFormatValid to set
	 * @since 1.50.0
	 */
	public void setSecondaryFormatValid(bool secondaryFormatValid) {
		this.secondaryFormatValid = secondaryFormatValid;
	}

	/**
	 * @return the parsing
	 * @since 1.50.0
	 */
	public bool isParsing() {
		return parsing;
	}

	/**
	 * @param parsing the parsing to set
	 * @since 1.50.0
	 */
	public void setParsing(bool parsing) {
		this.parsing = parsing;
	}

	/**
	 * @return the encrypted
	 * @since 1.50.0
	 */
	public bool isEncrypted() {
		return encrypted;
	}

	/**
	 * @param encrypted the encrypted to set
	 * @since 1.50.0
	 */
	public void setEncrypted(bool encrypted) {
		this.encrypted = encrypted;
	}
}
