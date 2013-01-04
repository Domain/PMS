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
module net.pms.encoders.TSMuxerVideo;

import net.pms.formats.v2.AudioUtils : getLPCMChannelMappingForMencoder;
import org.apache.commons.lang.StringUtils : isNotBlank;

//import java.awt.ComponentOrientation;
//import java.awt.Font;
//import java.awt.event.ItemEvent;
//import java.awt.event.ItemListener;
import java.io.File;
import java.io.FileOutputStream;
import java.lang.exceptions;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.net.URL;
import java.util.Locale;

//import javax.swing.JCheckBox;
//import javax.swing.JComponent;
//import javax.swing.JPanel;

import net.pms.Messages;
import net.pms.PMS;
import net.pms.configuration.PmsConfiguration;
import net.pms.configuration.RendererConfiguration;
import net.pms.dlna.DLNAMediaAudio;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.dlna.DLNAMediaSubtitle;
import net.pms.dlna.DLNAResource;
import net.pms.dlna.InputFile;
import net.pms.formats.Format;
import net.pms.io.OutputParams;
import net.pms.io.PipeIPCProcess;
import net.pms.io.PipeProcess;
import net.pms.io.ProcessWrapper;
import net.pms.io.ProcessWrapperImpl;
import net.pms.io.StreamModifier;
import net.pms.util.CodecUtil;
import net.pms.util.FormLayoutUtil;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

//import com.jgoodies.forms.builder.PanelBuilder;
//import com.jgoodies.forms.factories.Borders;
//import com.jgoodies.forms.layout.CellConstraints;
//import com.jgoodies.forms.layout.FormLayout;

public class TSMuxerVideo : Player {
	private static immutable Logger logger = LoggerFactory.getLogger!TSMuxerVideo();
	private static const String COL_SPEC = "left:pref, 0:grow";
	private static const String ROW_SPEC = "p, 3dlu, p, 3dlu, p, 3dlu, p, 3dlu, p, 3dlu, 0:grow";

	public static const String ID = "tsmuxer";
	private PmsConfiguration configuration;

	public this(PmsConfiguration configuration) {
		this.configuration = configuration;
	}

	public bool excludeFormat(Format extension) {
		String m = extension.getMatchedId();
		return m !is null && !m.opEquals("mp4") && !m.opEquals("mkv") && !m.opEquals("ts") && !m.opEquals("tp") && !m.opEquals("m2ts") && !m.opEquals("m2t") && !m.opEquals("mpg") && !m.opEquals("evo") && !m.opEquals("mpeg")
			&& !m.opEquals("vob") && !m.opEquals("m2v") && !m.opEquals("mts") && !m.opEquals("mov");
	}

	override
	public int purpose() {
		return VIDEO_SIMPLEFILE_PLAYER;
	}

	override
	public String id() {
		return ID;
	}

	override
	public bool isTimeSeekable() {
		return true;
	}

	override
	public String[] args() {
		return null;
	}

	override
	public String executable() {
		return configuration.getTsmuxerPath();
	}

	override
	public ProcessWrapper launchTranscode(
		String fileName,
		DLNAResource dlna,
		DLNAMediaInfo media,
		OutputParams params) {
		setAudioAndSubs(fileName, media, params, configuration);

		PipeIPCProcess ffVideoPipe = null;
		ProcessWrapperImpl ffVideo = null;

		PipeIPCProcess[] ffAudioPipe = null;
		ProcessWrapperImpl[] ffAudio = null;

		String fps = media.getValidFps(false);
		String videoType = "V_MPEG4/ISO/AVC";
		if (media !is null && media.getCodecV() !is null && media.getCodecV().opEquals("mpeg2video")) {
			videoType = "V_MPEG-2";
		}

		if (cast(TsMuxerAudio)this !is null && media.getFirstAudioTrack() !is null) {
			String fakeFileName = writeResourceToFile("/resources/images/fake.jpg"); 
			ffVideoPipe = new PipeIPCProcess(System.currentTimeMillis() ~ "fakevideo", System.currentTimeMillis() ~ "videoout", false, true);
			String[] ffmpegLPCMextract = [
				configuration.getFfmpegPath(),
				"-t", "" ~ params.timeend,
				"-loop", "1",
				"-i", fakeFileName,
				"-qcomp", "0.6",
				"-qmin", "10",
				"-qmax", "51",
				"-qdiff", "4",
				"-me_range", "4",
				"-f", "h264",
				"-vcodec", "libx264",
				"-an",
				"-y",
				ffVideoPipe.getInputPipe()
			];

			// videoType = "V_MPEG-2";
			videoType = "V_MPEG4/ISO/AVC";
			if (params.timeend < 1) {
				ffmpegLPCMextract[1] = "-y";
				ffmpegLPCMextract[2] = "-y";
			}

			OutputParams ffparams = new OutputParams(PMS.getConfiguration());
			ffparams.maxBufferSize = 1;
			ffVideo = new ProcessWrapperImpl(ffmpegLPCMextract, ffparams);

			if (fileName.toLowerCase().endsWith(".flac") && media !is null && media.getFirstAudioTrack().getBitsperSample() >= 24 && media.getFirstAudioTrack().getSampleRate() % 48000 == 0) {
				ffAudioPipe = new PipeIPCProcess[1];
				ffAudioPipe[0] = new PipeIPCProcess(System.currentTimeMillis().toString() ~ "flacaudio", System.currentTimeMillis().toString() ~ "audioout", false, true);

				String[] flacCmd = [
					configuration.getFlacPath(),
					"--output-name=" ~ ffAudioPipe[0].getInputPipe(),
					"-d",
					"-f",
					"-F",
					fileName
				];

				ffparams = new OutputParams(PMS.getConfiguration());
				ffparams.maxBufferSize = 1;
				ffAudio = new ProcessWrapperImpl[1];
				ffAudio[0] = new ProcessWrapperImpl(flacCmd, ffparams);
			} else {
				ffAudioPipe = new PipeIPCProcess[1];
				ffAudioPipe[0] = new PipeIPCProcess(System.currentTimeMillis().toString() ~ "mlpaudio", System.currentTimeMillis().toString() ~ "audioout", false, true);
				String depth = "pcm_s16le";
				String rate = "48000";

				if (media !is null && media.getFirstAudioTrack().getBitsperSample() >= 24) {
					depth = "pcm_s24le";
				}

				if (media !is null && media.getFirstAudioTrack().getSampleRate() > 48000) {
					rate = "" ~ media.getFirstAudioTrack().getSampleRate();
				}

				String[] flacCmd = [
					configuration.getFfmpegPath(),
					"-ar",
					rate,
					"-i",
					fileName,
					"-f",
					"wav",
					"-acodec",
					depth,
					"-y",
					ffAudioPipe[0].getInputPipe()
				];

				ffparams = new OutputParams(PMS.getConfiguration());
				ffparams.maxBufferSize = 1;
				ffAudio = new ProcessWrapperImpl[1];
				ffAudio[0] = new ProcessWrapperImpl(flacCmd, ffparams);
			}
		} else {
			params.waitbeforestart = 5000;
			params.manageFastStart();

			String mencoderPath = configuration.getMencoderPath();

			ffVideoPipe = new PipeIPCProcess(System.currentTimeMillis().toString() ~ "ffmpegvideo", System.currentTimeMillis().toString() ~ "videoout", false, true);

			String[] ffmpegLPCMextract = [
				mencoderPath,
				"-ss", "0",
				fileName,
				"-quiet",
				"-quiet",
				"-really-quiet",
				"-msglevel", "statusline=2",
				"-ovc", "copy",
				"-nosound",
				"-mc", "0",
				"-noskip",
				"-of", "rawvideo",
				"-o", ffVideoPipe.getInputPipe()
			];

			if (fileName.toLowerCase().endsWith(".evo")) {
				ffmpegLPCMextract[4] = "-psprobe";
				ffmpegLPCMextract[5] = "1000000";
			}

			if (params.stdin !is null) {
				ffmpegLPCMextract[3] = "-";
			}

			InputFile newInput = new InputFile();
			newInput.setFilename(fileName);
			newInput.setPush(params.stdin);

			if (media !is null) {
				bool compat = (media.isVideoPS3Compatible(newInput) || !params.mediaRenderer.isH264Level41Limited());

				if (!compat && params.mediaRenderer.isPS3()) {
					logger.info("The video will not play or will show a black screen on the PS3...");
				}

				if (media.getH264AnnexB() !is null && media.getH264AnnexB().length > 0) {
					StreamModifier sm = new StreamModifier();
					sm.setHeader(media.getH264AnnexB());
					sm.setH264AnnexB(true);
					ffVideoPipe.setModifier(sm);
				}
			}

			if (params.timeseek > 0) {
				ffmpegLPCMextract[2] = "" ~ params.timeseek.toString();
			}

			OutputParams ffparams = new OutputParams(PMS.getConfiguration());
			ffparams.maxBufferSize = 1;
			ffparams.stdin = params.stdin;
			ffVideo = new ProcessWrapperImpl(ffmpegLPCMextract, ffparams);

			int numAudioTracks = 1;

			if (media !is null && media.getAudioTracksList() !is null && media.getAudioTracksList().size() > 1 && configuration.isMuxAllAudioTracks()) {
				numAudioTracks = media.getAudioTracksList().size();
			}

			bool singleMediaAudio = media !is null && media.getAudioTracksList().size() <= 1;

			if (params.aid !is null) {
				bool ac3Remux = false;
				bool dtsRemux = false;
				bool pcm = false;
				// disable LPCM transcoding for MP4 container with non-H264 video as workaround for mencoder's A/V sync bug
				bool mp4_with_non_h264 = (media.getContainer().opEquals("mp4") && !media.getCodecV().opEquals("h264"));
				if (numAudioTracks <= 1) {
					ffAudioPipe = new PipeIPCProcess[numAudioTracks];
					ffAudioPipe[0] = new PipeIPCProcess(System.currentTimeMillis().toString() ~ "ffmpegaudio01", System.currentTimeMillis().toString() ~ "audioout", false, true);
                    // disable AC-3 remux for stereo tracks with 384 kbits bitrate and PS3 renderer (PS3 FW bug?)
					bool ps3_and_stereo_and_384_kbits = (params.mediaRenderer.isPS3() && params.aid.getAudioProperties().getNumberOfChannels() == 2)
						&& (params.aid.getBitRate() > 370000 && params.aid.getBitRate() < 400000);
					ac3Remux = (params.aid.isAC3() && !ps3_and_stereo_and_384_kbits && configuration.isRemuxAC3());
                    dtsRemux = configuration.isDTSEmbedInPCM() && params.aid.isDTS() && params.mediaRenderer.isDTSPlayable();
					pcm = configuration.isMencoderUsePcm() &&
						!mp4_with_non_h264 &&
						(
							params.aid.isLossless() ||
							(params.aid.isDTS() && params.aid.getAudioProperties().getNumberOfChannels() <= 6) ||
							params.aid.isTrueHD() ||
							(
								!configuration.isMencoderUsePcmForHQAudioOnly() &&
								(
									params.aid.isAC3() ||
									params.aid.isMP3() ||
									params.aid.isAAC() ||
									params.aid.isVorbis() ||
									// params.aid.isWMA() ||
									params.aid.isMpegAudio()
								)
							)
						) && params.mediaRenderer.isLPCMPlayable();

					int channels;
					if (ac3Remux) {
						channels = params.aid.getAudioProperties().getNumberOfChannels(); // AC-3 remux
					} else if (dtsRemux) {
						channels = 2;
					} else if (pcm) {
						channels = params.aid.getAudioProperties().getNumberOfChannels();
					} else {
						channels = configuration.getAudioChannelCount(); // 5.1 max for AC-3 encoding
					}

					if ( !ac3Remux && (dtsRemux || pcm) ) {
						// DTS remux or LPCM
						StreamModifier sm = new StreamModifier();
						sm.setPcm(pcm);
						sm.setDtsEmbed(dtsRemux);
						sm.setNbChannels(channels);
						sm.setSampleFrequency(params.aid.getSampleRate() < 48000 ? 48000 : params.aid.getSampleRate());
						sm.setBitsPerSample(16);
						String mixer = null;

						if (pcm && !dtsRemux) {
							mixer = getLPCMChannelMappingForMencoder(params.aid);
						}

						ffmpegLPCMextract = [
							mencoderPath,
							"-ss", "0",
							fileName,
							"-quiet",
							"-quiet",
							"-really-quiet",
							"-msglevel", "statusline=2",
							"-channels", "" ~ sm.getNbChannels(),
							"-ovc", "copy",
							"-of", "rawaudio",
							"-mc", sm.isDtsEmbed() ? "0.1" : "0",
							"-noskip",
							"-oac", sm.isDtsEmbed() ? "copy" : "pcm",
							isNotBlank(mixer) ? "-af" : "-quiet", isNotBlank(mixer) ? mixer : "-quiet",
							singleMediaAudio ? "-quiet" : "-aid", singleMediaAudio ? "-quiet" : (params.aid.getId().toString()),
							"-srate", "48000",
							"-o", ffAudioPipe[0].getInputPipe()
						];

						if (!params.mediaRenderer.isMuxDTSToMpeg()) { // use PCM trick when media renderer does not support DTS in MPEG
							ffAudioPipe[0].setModifier(sm);
						}
					} else {
						// AC-3 remux or encoding
						ffmpegLPCMextract = [
							mencoderPath,
							"-ss", "0",
							fileName,
							"-quiet",
							"-quiet",
							"-really-quiet",
							"-msglevel", "statusline=2",
							"-channels", "" ~ channels,
							"-ovc", "copy",
							"-of", "rawaudio",
							"-mc", "0",
							"-noskip",
							"-oac", (ac3Remux) ? "copy" : "lavc",
							params.aid.isAC3() ? "-fafmttag" : "-quiet", params.aid.isAC3() ? "0x2000" : "-quiet",
							"-lavcopts", "acodec=" ~ (configuration.isMencoderAc3Fixed() ? "ac3_fixed" : "ac3") + ":abitrate=" ~ CodecUtil.getAC3Bitrate(configuration, params.aid).toString(),
							"-af", "lavcresample=48000",
							"-srate", "48000",
							singleMediaAudio ? "-quiet" : "-aid", singleMediaAudio ? "-quiet" : (params.aid.getId().toString()),
							"-o", ffAudioPipe[0].getInputPipe()
						];
					}

					if (fileName.toLowerCase().endsWith(".evo")) {
						ffmpegLPCMextract[4] = "-psprobe";
						ffmpegLPCMextract[5] = "1000000";
					}

					if (params.stdin !is null) {
						ffmpegLPCMextract[3] = "-";
					}

					if (params.timeseek > 0) {
						ffmpegLPCMextract[2] = "" ~ params.timeseek.toString();
					}

					ffparams = new OutputParams(PMS.getConfiguration());
					ffparams.maxBufferSize = 1;
					ffparams.stdin = params.stdin;
					ffAudio = new ProcessWrapperImpl[numAudioTracks];
					ffAudio[0] = new ProcessWrapperImpl(ffmpegLPCMextract, ffparams);
				} else {
					ffAudioPipe = new PipeIPCProcess[numAudioTracks];
					ffAudio = new ProcessWrapperImpl[numAudioTracks];
					for (int i = 0; i < media.getAudioTracksList().size(); i++) {
						DLNAMediaAudio audio = media.getAudioTracksList().get(i);
						ffAudioPipe[i] = new PipeIPCProcess(System.currentTimeMillis().toString() ~ "ffmpeg" ~ i.toString(), System.currentTimeMillis().toString() ~ "audioout" ~ i.toString(), false, true);
                        // disable AC-3 remux for stereo tracks with 384 kbits bitrate and PS3 renderer (PS3 FW bug?)
						bool ps3_and_stereo_and_384_kbits = (params.mediaRenderer.isPS3() && audio.getAudioProperties().getNumberOfChannels() == 2)
							&& (audio.getBitRate() > 370000 && audio.getBitRate() < 400000);
                        ac3Remux = audio.isAC3() && !ps3_and_stereo_and_384_kbits && configuration.isRemuxAC3();
						dtsRemux = configuration.isDTSEmbedInPCM() && audio.isDTS() && params.mediaRenderer.isDTSPlayable();
						pcm = configuration.isMencoderUsePcm() &&
							!mp4_with_non_h264 &&
							(
								audio.isLossless() ||
								(audio.isDTS() && audio.getAudioProperties().getNumberOfChannels() <= 6) ||
								audio.isTrueHD() ||
								(
									!configuration.isMencoderUsePcmForHQAudioOnly() &&
									(
										audio.isAC3() ||
										audio.isMP3() ||
										audio.isAAC() ||
										audio.isVorbis() ||
										// audio.isWMA() ||
										audio.isMpegAudio()
									)
								)
							) && params.mediaRenderer.isLPCMPlayable();

						int channels;
						if (ac3Remux) {
							channels = audio.getAudioProperties().getNumberOfChannels(); // AC-3 remux
						} else if (dtsRemux) {
							channels = 2;
						} else if (pcm) {
							channels = audio.getAudioProperties().getNumberOfChannels();
						} else {
							channels = configuration.getAudioChannelCount(); // 5.1 max for AC-3 encoding
						}

						if ( !ac3Remux && (dtsRemux || pcm) ) {
							// DTS remux or LPCM
							StreamModifier sm = new StreamModifier();
							sm.setPcm(pcm);
							sm.setDtsEmbed(dtsRemux);
							sm.setNbChannels(channels);
							sm.setSampleFrequency(audio.getSampleRate() < 48000 ? 48000 : audio.getSampleRate());
							sm.setBitsPerSample(16);
							if (!params.mediaRenderer.isMuxDTSToMpeg()) {
								ffAudioPipe[i].setModifier(sm);
							}
							String mixer = null;
							if (pcm && !dtsRemux) {
								mixer = getLPCMChannelMappingForMencoder(audio);
							}
							ffmpegLPCMextract = [
								mencoderPath,
								"-ss", "0",
								fileName,
								"-quiet",
								"-quiet",
								"-really-quiet",
								"-msglevel", "statusline=2",
								"-channels", "" ~ sm.getNbChannels(),
								"-ovc", "copy",
								"-of", "rawaudio",
								"-mc", sm.isDtsEmbed() ? "0.1" : "0",
								"-noskip",
								"-oac", sm.isDtsEmbed() ? "copy" : "pcm",
								isNotBlank(mixer) ? "-af" : "-quiet", isNotBlank(mixer) ? mixer : "-quiet",
								singleMediaAudio ? "-quiet" : "-aid", singleMediaAudio ? "-quiet" : audio.getId().toString(),
								"-srate", "48000",
								"-o", ffAudioPipe[i].getInputPipe()
							];
						} else {
							// AC-3 remux or encoding
							ffmpegLPCMextract = [
								mencoderPath,
								"-ss", "0",
								fileName,
								"-quiet",
								"-quiet",
								"-really-quiet",
								"-msglevel", "statusline=2",
								"-channels", "" ~ channels,
								"-ovc", "copy",
								"-of", "rawaudio",
								"-mc", "0",
								"-noskip",
								"-oac", (ac3Remux) ? "copy" : "lavc",
								audio.isAC3() ? "-fafmttag" : "-quiet", audio.isAC3() ? "0x2000" : "-quiet",
								"-lavcopts", "acodec=" ~ (configuration.isMencoderAc3Fixed() ? "ac3_fixed" : "ac3") ~ ":abitrate=" ~ CodecUtil.getAC3Bitrate(configuration, audio).toString(),
								"-af", "lavcresample=48000",
								"-srate", "48000",
								singleMediaAudio ? "-quiet" : "-aid", singleMediaAudio ? "-quiet" : audio.getId().toString(),
								"-o", ffAudioPipe[i].getInputPipe()
							];
						}

						if (fileName.toLowerCase().endsWith(".evo")) {
							ffmpegLPCMextract[4] = "-psprobe";
							ffmpegLPCMextract[5] = "1000000";
						}

						if (params.stdin !is null) {
							ffmpegLPCMextract[3] = "-";
						}
						if (params.timeseek > 0) {
							ffmpegLPCMextract[2] = params.timeseek.toString();
						}
						ffparams = new OutputParams(PMS.getConfiguration());
						ffparams.maxBufferSize = 1;
						ffparams.stdin = params.stdin;
						ffAudio[i] = new ProcessWrapperImpl(ffmpegLPCMextract, ffparams);
					}
				}
			}
		}

		File f = new File(configuration.getTempFolder(), "pms-tsmuxer.meta");
		params.log = false;
		PrintWriter pw = new PrintWriter(f);
		pw.print("MUXOPT --no-pcr-on-video-pid");
		pw.print(" --new-audio-pes");
		if (ffVideo !is null) {
			pw.print(" --no-asyncio");
		}
		pw.print(" --vbr");
		pw.println(" --vbv-len=500");

		if (ffVideoPipe !is null) {
			String videoparams = "level=4.1, insertSEI, contSPS, track=1";
			if (cast(TsMuxerAudio)this !is null) {
				videoparams = "track=224";
			}
			if (configuration.isFix25FPSAvMismatch()) {
				fps = "25";
			}
			pw.println(videoType ~ ", \"" ~ ffVideoPipe.getOutputPipe() ~ "\", " ~ (fps !is null ? ("fps=" ~ fps ~ ", ") : "") ~ videoparams);
		}
		// disable LPCM transcoding for MP4 container with non-H264 video as workaround for mencoder's A/V sync bug
		bool mp4_with_non_h264 = (media.getContainer().opEquals("mp4") && !media.getCodecV().opEquals("h264"));
		if (ffAudioPipe !is null && ffAudioPipe.length == 1) {
			String timeshift = "";
			bool ac3Remux = false;
			bool dtsRemux = false;
			bool pcm = false;
			bool ps3_and_stereo_and_384_kbits = (params.mediaRenderer.isPS3() && params.aid.getAudioProperties().getNumberOfChannels() == 2)
				&& (params.aid.getBitRate() > 370000 && params.aid.getBitRate() < 400000);
			ac3Remux = params.aid.isAC3() && !ps3_and_stereo_and_384_kbits && configuration.isRemuxAC3();
			dtsRemux = configuration.isDTSEmbedInPCM() && params.aid.isDTS() && params.mediaRenderer.isDTSPlayable();
			pcm = configuration.isMencoderUsePcm() &&
				!mp4_with_non_h264 &&
				(
					params.aid.isLossless() ||
					(params.aid.isDTS() && params.aid.getAudioProperties().getNumberOfChannels() <= 6) ||
					params.aid.isTrueHD() ||
					(
						!configuration.isMencoderUsePcmForHQAudioOnly() &&
						(
							params.aid.isAC3() ||
							params.aid.isMP3() ||
							params.aid.isAAC() ||
							params.aid.isVorbis() ||
							// params.aid.isWMA() ||
							params.aid.isMpegAudio()
						)
					)
				) && params.mediaRenderer.isLPCMPlayable();
			String type = "A_AC3";
			if (ac3Remux) {
				// AC-3 remux takes priority
				type = "A_AC3";
			} else {
				if ( pcm || cast(TsMuxerAudio)this !is null )
				{
					type = "A_LPCM";
				}
				if ( dtsRemux || cast(TsMuxerAudio)this !is null )
				{
					type = "A_LPCM";
					if (params.mediaRenderer.isMuxDTSToMpeg()) {
						type = "A_DTS";
					}
				}
			}
			if (params.aid !is null && params.aid.getAudioProperties().getAudioDelay() != 0 && params.timeseek == 0) {
				timeshift = "timeshift=" ~ params.aid.getAudioProperties().getAudioDelay().toString() ~ "ms, ";
			}
			pw.println(type ~ ", \"" ~ ffAudioPipe[0].getOutputPipe() ~ "\", " ~ timeshift ~ "track=2");
		} else if (ffAudioPipe !is null) {
			for (int i = 0; i < media.getAudioTracksList().size(); i++) {
				DLNAMediaAudio lang = media.getAudioTracksList().get(i);
				String timeshift = "";
				bool ac3Remux = false;
				bool dtsRemux = false;
				bool pcm = false;
                bool ps3_and_stereo_and_384_kbits = (params.mediaRenderer.isPS3() && lang.getAudioProperties().getNumberOfChannels() == 2)
					&& (lang.getBitRate() > 370000 && lang.getBitRate() < 400000);
                ac3Remux = lang.isAC3() && !ps3_and_stereo_and_384_kbits && configuration.isRemuxAC3();
				dtsRemux = configuration.isDTSEmbedInPCM() && lang.isDTS() && params.mediaRenderer.isDTSPlayable();
				pcm = configuration.isMencoderUsePcm() &&
					!mp4_with_non_h264 &&
					(
						lang.isLossless() ||
						(lang.isDTS() && lang.getAudioProperties().getNumberOfChannels() <= 6) ||
						lang.isTrueHD() ||
						(
							!configuration.isMencoderUsePcmForHQAudioOnly() &&
							(
								params.aid.isAC3() ||
								params.aid.isMP3() ||
								params.aid.isAAC() ||
								params.aid.isVorbis() ||
								// params.aid.isWMA() ||
								params.aid.isMpegAudio()
							)
						)
					) && params.mediaRenderer.isLPCMPlayable();
				String type = "A_AC3";
				if (ac3Remux) {
					// AC-3 remux takes priority
					type = "A_AC3";
				} else {
					if ( pcm )
					{
						type = "A_LPCM";
					}
					if ( dtsRemux )
					{
						type = "A_LPCM";
						if (params.mediaRenderer.isMuxDTSToMpeg()) {
							type = "A_DTS";
						}
					}
				}
				if (lang.getAudioProperties().getAudioDelay() != 0 && params.timeseek == 0) {
					timeshift = "timeshift=" ~ lang.getAudioProperties().getAudioDelay().toString() ~ "ms, ";
				}
				pw.println(type ~ ", \"" ~ ffAudioPipe[i].getOutputPipe() ~ "\", " ~ timeshift ~ "track=" ~ (2 + i).toString());
			}
		}

		pw.close();

		PipeProcess tsPipe = new PipeProcess(System.currentTimeMillis().toString() ~ "tsmuxerout.ts");
		String[] cmdArray = [
			executable(),
			f.getAbsolutePath(),
			tsPipe.getInputPipe()
		];

		cmdArray = finalizeTranscoderArgs(
			fileName,
			dlna,
			media,
			params,
			cmdArray
		);

		ProcessWrapperImpl p = new ProcessWrapperImpl(cmdArray, params);
		params.maxBufferSize = 100;
		params.input_pipes[0] = tsPipe;
		params.stdin = null;
		ProcessWrapper pipe_process = tsPipe.getPipeProcess();
		p.attachProcess(pipe_process);
		pipe_process.runInNewThread();

		try {
			Thread.sleep(50);
		} catch (InterruptedException e) { }

		tsPipe.deleteLater();

		if (ffVideoPipe !is null) {
			ProcessWrapper ff_pipe_process = ffVideoPipe.getPipeProcess();
			p.attachProcess(ff_pipe_process);
			ff_pipe_process.runInNewThread();

			try {
				Thread.sleep(50);
			} catch (InterruptedException e) { }

			ffVideoPipe.deleteLater();

			p.attachProcess(ffVideo);
			ffVideo.runInNewThread();

			try {
				Thread.sleep(50);
			} catch (InterruptedException e) { }
		}

		if (ffAudioPipe !is null && params.aid !is null) {
			for (int i = 0; i < ffAudioPipe.length; i++) {
				ProcessWrapper ff_pipe_process = ffAudioPipe[i].getPipeProcess();
				p.attachProcess(ff_pipe_process);
				ff_pipe_process.runInNewThread();

				try {
					Thread.sleep(50);
				} catch (InterruptedException e) { }

				ffAudioPipe[i].deleteLater();
				p.attachProcess(ffAudio[i]);
				ffAudio[i].runInNewThread();
			}
		}

		try {
			Thread.sleep(100);
		} catch (InterruptedException e) { }

		p.runInNewThread();

		return p;
	}

	/**
	 * Write the resource "/resources/images/fake.jpg" to a physical file on disk.
	 *
	 * @return The filename of the file on disk.
	 */
	private String writeResourceToFile(String resourceName) {
		String outputFileName = resourceName.substring(resourceName.lastIndexOf("/") + 1);

		try {
			outputFileName = PMS.getConfiguration().getTempFolder() ~ "/" ~ outputFileName;
		} catch (IOException e) {
			logger.warn("Failure to determine temporary folder.", e);
		}

		File outputFile = new File(outputFileName);

		// Copy the resource file only once
		if (!outputFile.exists()) {
			immutable URL resourceUrl = getClass().getClassLoader().getResource(resourceName);
			byte[] buffer = new byte[1024];
			int byteCount = 0;
	
			InputStream inputStream = null;
			OutputStream outputStream = null;
	
			try {
				inputStream = resourceUrl.openStream();
				outputStream = new FileOutputStream(outputFileName);
	
				while ((byteCount = inputStream.read(buffer)) >= 0) {
					outputStream.write(buffer, 0, byteCount);
				}
			} catch (IOException e) {
				logger.error("Failure on saving the embedded resource " ~ resourceName
						~ " to the file " ~ outputFile.getAbsolutePath(), e);
			} finally {
				if (inputStream !is null) {
					try {
						inputStream.close();
					} catch (IOException e) {
						logger.warn("Problem closing an input stream while reading data from the embedded resource "
								~ resourceName, e);
					}
				}
	
				if (outputStream !is null) {
					try {
						outputStream.flush();
						outputStream.close();
					} catch (IOException e) {
						logger.warn("Problem closing the output stream while writing the file "
								~ outputFile.getAbsolutePath(), e);
					}
				}
			}
		}

		return outputFileName;
	}

	override
	public String mimeType() {
		return "video/mpeg";
	}

	override
	public String name() {
		return "tsMuxeR";
	}

	override
	public int type() {
		return Format.VIDEO;
	}
	private JCheckBox tsmuxerforcefps;
	private JCheckBox muxallaudiotracks;

	override
	public JComponent config() {
		// Apply the orientation for the locale
		Locale locale = new Locale(configuration.getLanguage());
		ComponentOrientation orientation = ComponentOrientation.getOrientation(locale);
		String colSpec = FormLayoutUtil.getColSpec(COL_SPEC, orientation);
		FormLayout layout = new FormLayout(colSpec, ROW_SPEC);

		PanelBuilder builder = new PanelBuilder(layout);
		builder.setBorder(Borders.EMPTY_BORDER);
		builder.setOpaque(false);

		CellConstraints cc = new CellConstraints();


		JComponent cmp = builder.addSeparator(Messages.getString("TSMuxerVideo.3"), FormLayoutUtil.flip(cc.xyw(2, 1, 1), colSpec, orientation));
		cmp = cast(JComponent) cmp.getComponent(0);
		cmp.setFont(cmp.getFont().deriveFont(Font.BOLD));

		tsmuxerforcefps = new JCheckBox(Messages.getString("TSMuxerVideo.2"));
		tsmuxerforcefps.setContentAreaFilled(false);
		if (configuration.isTsmuxerForceFps()) {
			tsmuxerforcefps.setSelected(true);
		}
		tsmuxerforcefps.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				configuration.setTsmuxerForceFps(e.getStateChange() == ItemEvent.SELECTED);
			}
		});
		builder.add(tsmuxerforcefps, FormLayoutUtil.flip(cc.xy(2, 3), colSpec, orientation));

		muxallaudiotracks = new JCheckBox(Messages.getString("TSMuxerVideo.19"));
		muxallaudiotracks.setContentAreaFilled(false);
		if (configuration.isMuxAllAudioTracks()) {
			muxallaudiotracks.setSelected(true);
		}

		muxallaudiotracks.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				configuration.setMuxAllAudioTracks(e.getStateChange() == ItemEvent.SELECTED);
			}
		});
		builder.add(muxallaudiotracks, FormLayoutUtil.flip(cc.xy(2, 5), colSpec, orientation));

		JPanel panel = builder.getPanel();

		// Apply the orientation to the panel and all components in it
		panel.applyComponentOrientation(orientation);

		return panel;
	}

	public bool isInternalSubtitlesSupported() {
		return false;
	}

	public bool isExternalSubtitlesSupported() {
		return false;
	}

	override
	public bool isPlayerCompatible(RendererConfiguration mediaRenderer) {
		return mediaRenderer !is null && mediaRenderer.isMuxH264MpegTS();
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public bool isCompatible(DLNAResource resource) {
		if (resource is null || resource.getFormat().getType() != Format.VIDEO) {
			return false;
		}

		DLNAMediaSubtitle subtitle = resource.getMediaSubtitle();

		// Check whether the subtitle actually has a language defined,
		// uninitialized DLNAMediaSubtitle objects have a null language.
		if (subtitle !is null && subtitle.getLang() !is null) {
			// The resource needs a subtitle, but PMS does not support subtitles for tsMuxeR.
			return false;
		}

		try {
			String audioTrackName = resource.getMediaAudio().toString();
			String defaultAudioTrackName = resource.getMedia().getAudioTracksList().get(0).toString();
	
			if (!audioTrackName.opEquals(defaultAudioTrackName)) {
				// PMS only supports playback of the default audio track for tsMuxeR
				return false;
			}
		} catch (NullPointerException e) {
			logger.trace("FFmpeg cannot determine compatibility based on audio track for "
					~ resource.getSystemName());
		} catch (IndexOutOfBoundsException e) {
			logger.trace("FFmpeg cannot determine compatibility based on default audio track for "
					~ resource.getSystemName());
		}

		Format format = resource.getFormat();

		if (format !is null) {
			Format.Identifier id = format.getIdentifier();

			if (id.opEquals(Format.Identifier.MKV)
					|| id.opEquals(Format.Identifier.MPG)) {
				return true;
			}
		}

		return false;
	}
}
