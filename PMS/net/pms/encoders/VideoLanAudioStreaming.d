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
module net.pms.encoders.VideoLanAudioStreaming;

import net.pms.configuration.PmsConfiguration;
import net.pms.dlna.DLNAResource;
import net.pms.formats.Format;

public class VideoLanAudioStreaming : VideoLanVideoStreaming {
	public static final String ID = "vlcaudio";

	public VideoLanAudioStreaming(PmsConfiguration configuration) {
		super(configuration);
	}

	override
	public int purpose() {
		return AUDIO_WEBSTREAM_PLAYER;
	}

	override
	public String id() {
		return ID;
	}

	override
	public String name() {
		return "VLC Audio Streaming";
	}

	override
	public int type() {
		return Format.AUDIO;
	}

	override
	public String mimeType() {
		return "audio/wav";
	}

	override
	protected String getEncodingArgs() {
		return "acodec=s16l,channels=2";
	}

	override
	protected String getMux() {
		return "wav";
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public bool isCompatible(DLNAResource resource) {
		if (resource is null || resource.getFormat().getType() != Format.AUDIO) {
			return false;
		}

		Format format = resource.getFormat();

		if (format !is null) {
			Format.Identifier id = format.getIdentifier();

			if (id.equals(Format.Identifier.WEB)) {
				return true;
			}
		}

		return false;
	}
}
