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
module net.pms.encoders.FFMpegAviSynthVideo;

import java.io.File;
import java.io.FileOutputStream;
import java.lang.exceptions;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.StringTokenizer;

//import javax.swing.JComponent;

import net.pms.PMS;
import net.pms.dlna.DLNAMediaSubtitle;
import net.pms.dlna.DLNAResource;
import net.pms.formats.Format;
import net.pms.formats.v2.SubtitleType;
import net.pms.util.ProcessUtil;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This class handles the Windows specific AviSynth/FFmpeg player combination. 
 */
public class FFMpegAviSynthVideo : FFMpegVideo {
	private static immutable Logger logger = LoggerFactory.getLogger!FFMpegAviSynthVideo();
	public static const String ID      = "avsffmpeg";

	override
	public String id() {
		return ID;
	}

	override
	public String name() {
		return "AviSynth/FFmpeg";
	}

	override
	public bool avisynth() {
		return true;
	}

	override
	public JComponent config() {
		return config("FFMpegVideo.0");
	}

	public static File getAVSScript(String fileName, DLNAMediaSubtitle subTrack) {
		return getAVSScript(fileName, subTrack, -1, -1);
	}

	public static File getAVSScript(String fileName, DLNAMediaSubtitle subTrack, int fromFrame, int toFrame) {
		String onlyFileName = fileName.substring(1 + fileName.lastIndexOf("\\"));
		File file = new File(PMS.getConfiguration().getTempFolder(), "pms-avs-" ~ onlyFileName ~ ".avs");
		PrintWriter pw = new PrintWriter(new FileOutputStream(file));

		String convertfps = "";
		if (PMS.getConfiguration().getAvisynthConvertFps()) {
			convertfps = ", convertfps=true";
		}
		File f = new File(fileName);
		if (f.exists()) {
			fileName = ProcessUtil.getShortFileNameIfWideChars(fileName);
		}
		String movieLine = "clip=DirectShowSource(\"" ~ fileName ~ "\"" ~ convertfps ~ ")";
		String subLine = null;
		if (subTrack !is null && PMS.getConfiguration().isAutoloadSubtitles() && !PMS.getConfiguration().isMencoderDisableSubs()) {
			logger.trace("Avisynth script: Using sub track: " ~ subTrack);
			if (subTrack.getExternalFile() !is null) {
				String _function = "TextSub";
				if (subTrack.getType() == SubtitleType.VOBSUB) {
					_function = "VobSub";
				}
				subLine = "clip=" ~ _function ~ "(clip, \"" ~ ProcessUtil.getShortFileNameIfWideChars(subTrack.getExternalFile().getAbsolutePath()) ~ "\")";
			}
		}

		ArrayList/*<String>*/ lines = new ArrayList/*<String>*/();

		bool fullyManaged = false;
		String script = PMS.getConfiguration().getAvisynthScript();
		StringTokenizer st = new StringTokenizer(script, PMS.AVS_SEPARATOR);
		while (st.hasMoreTokens()) {
			String line = st.nextToken();
			if (line.contains("<movie") || line.contains("<sub"))
			{
				fullyManaged = true;
			}
			lines.add(line);
		}

		if (fullyManaged) {
			foreach (String s ; lines) {
				s = s.replace("<moviefilename>", fileName);
				if (movieLine !is null) {
					s = s.replace("<movie>", movieLine);
				}
				s = s.replace("<sub>", subLine !is null ? subLine : "#");
				pw.println(s);
			}
		} else {
			pw.println(movieLine);
			if (subLine !is null) {
				pw.println(subLine);
			}
			pw.println("clip");

		}

		pw.close();
		file.deleteOnExit();
		return file;
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public bool isCompatible(DLNAResource resource) {
		if (resource is null || resource.getFormat().getType() != Format.VIDEO) {
			return false;
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
