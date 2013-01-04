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
module net.pms.formats.WEB;

import java.util.ArrayList;

import net.pms.PMS;
import net.pms.configuration.RendererConfiguration;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.encoders.FFMpegWebVideo;
import net.pms.encoders.MEncoderWebVideo;
import net.pms.encoders.MPlayerWebAudio;
import net.pms.encoders.MPlayerWebVideoDump;
import net.pms.encoders.Player;
import net.pms.encoders.VideoLanAudioStreaming;
import net.pms.encoders.VideoLanVideoStreaming;

public class WEB : Format {
	/**
	 * {@inheritDoc} 
	 */
	override
	public Identifier getIdentifier() {
		return Identifier.WEB;
	}

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
	override
	public bool ps3compatible() {
		return type == IMAGE;
	}

	override
	public ArrayList/*<Class<? : Player>>*/ getProfiles() {
		ArrayList/*<Class<? : Player>>*/ a = new ArrayList/*<Class<? : Player>>*/();
		if (type == AUDIO) {
			PMS r = PMS.get();
			foreach (String engine ; PMS.getConfiguration().getEnginesAsList(r.getRegistry())) {
				if (engine.opEquals(MPlayerWebAudio.ID)) {
					a.add(MPlayerWebAudio._class);
				} else if (engine.opEquals(VideoLanAudioStreaming.ID)) {
					a.add(VideoLanAudioStreaming._class);
				}
			}
		} else {
			PMS r = PMS.get();
			foreach (String engine ; PMS.getConfiguration().getEnginesAsList(r.getRegistry())) {
				if (engine.opEquals(FFMpegWebVideo.ID)) {
					a.add(FFMpegWebVideo._class);
				} else if (engine.opEquals(MEncoderWebVideo.ID)) {
					a.add(MEncoderWebVideo._class);
				} else if (engine.opEquals(VideoLanVideoStreaming.ID)) {
					a.add(VideoLanVideoStreaming._class);
				} else if (engine.opEquals(MPlayerWebVideoDump.ID)) {
					a.add(MPlayerWebVideoDump._class);
				}
			}
		}

		return a;
	}

	/**
	 * {@inheritDoc}
	 */
	override
	// TODO remove screen - it's been tried numerous times (see forum) and it doesn't work
	public String[] getId() {
		return [ "http", "mms", "mmsh", "mmst", "rtsp", "rtp", "udp", "screen" ];
	}

	override
	public bool transcodable() {
		return true;
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public bool isCompatible(DLNAMediaInfo media, RendererConfiguration renderer) {
		// Emulating ps3compatible()
		return type == IMAGE;
	}
}
