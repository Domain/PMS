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
module net.pms.formats.DVRMS;

import net.pms.PMS;
import net.pms.encoders.FFMpegDVRMSRemux;
import net.pms.encoders.Player;

import java.util.ArrayList;

public class DVRMS : Format {
	/**
	 * {@inheritDoc} 
	 */
	override
	public Identifier getIdentifier() {
		return Identifier.DVRMS;
	}

	override
	public ArrayList/*<Class<? : Player>>*/ getProfiles() {
		ArrayList/*<Class<? : Player>>*/ a = new ArrayList/*<Class<? : Player>>*/();
		PMS r = PMS.get();
		foreach (String engine ; PMS.getConfiguration().getEnginesAsList(r.getRegistry())) {
			/*if (engine.opEquals(MEncoderVideo.ID))
			a.add(MEncoderVideo._class);*/
			if (engine.opEquals(FFMpegDVRMSRemux.ID)) {
				a.add(FFMpegDVRMSRemux._class);
			}
		}
		return a;
	}

	override
	public bool transcodable() {
		return true;
	}

	public this() {
		type = VIDEO;
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public String[] getId() {
		return [ "dvr-ms", "dvr" ];
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
		return false;
	}
}
