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
module net.pms.encoders.TsMuxerAudio;

import net.pms.configuration.PmsConfiguration;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.dlna.DLNAResource;
import net.pms.formats.Format;
import net.pms.io.OutputParams;
import net.pms.io.ProcessWrapper;

import java.io.IOException;

public class TsMuxerAudio : TSMuxerVideo {
	public static const String ID = "tsmuxeraudio";

	public this(PmsConfiguration configuration) {
		super(configuration);
	}

	override
	public JComponent config() {
		return null;
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
	public ProcessWrapper launchTranscode(
		String fileName,
		DLNAResource dlna,
		DLNAMediaInfo media,
		OutputParams params) {
		params.timeend = media.getDurationInSeconds();
		params.waitbeforestart = 2500;
		return super.launchTranscode(fileName, dlna, media, params);
	}

	override
	public String name() {
		return "Audio High Fidelity";
	}

	override
	public int purpose() {
		return AUDIO_SIMPLEFILE_PLAYER;
	}

	override
	public int type() {
		return Format.VIDEO;
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

			if (id.opEquals(Format.Identifier.AUDIO_AS_VIDEO)) {
				return true;
			}
		}

		return false;
	}
}
