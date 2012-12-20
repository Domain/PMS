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
module net.pms.formats.MPG;

import net.pms.PMS;
import net.pms.encoders.all;

import java.util.ArrayList;

public class MPG : Format {
	/**
	 * {@inheritDoc} 
	 */
	override
	public Identifier getIdentifier() {
		return Identifier.MPG;
	}

	override
	public ArrayList/*<Class<? : Player>>*/ getProfiles() {
		PMS r = PMS.get();
		PMS r1 = PMS.get();
		PMS r2 = PMS.get();
		if (PMS.getConfiguration().getEnginesAsList(r.getRegistry()) is null || PMS.getConfiguration().getEnginesAsList(r1.getRegistry()).isEmpty() || PMS.getConfiguration().getEnginesAsList(r2.getRegistry()).contains("none"))
		{
			return null;
		}
		ArrayList/*<Class<? : Player>>*/ a = new ArrayList/*<Class<? : Player>>*/();
		PMS r3 = PMS.get();
		for (String engine : PMS.getConfiguration().getEnginesAsList(r3.getRegistry())) {
			if (engine.equals(MEncoderVideo.ID)) {
				a.add(MEncoderVideo.class);
			} else if (engine.equals(MEncoderAviSynth.ID) && PMS.get().getRegistry().isAvis()) {
				a.add(MEncoderAviSynth.class);
			} else if (engine.equals(FFMpegVideo.ID)) {
				a.add(FFMpegVideo.class);
			} else if (engine.equals(FFMpegAviSynthVideo.ID) && PMS.get().getRegistry().isAvis()) {
				a.add(FFMpegAviSynthVideo.class);
			} else if (engine.equals(TSMuxerVideo.ID)/* && PMS.get().isWindows()*/) {
				a.add(TSMuxerVideo.class);
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
		String[] id = [ "mpg", "mpeg", "mpe", "mod", "tivo", "ty", "tmf",
				"ts", "tp", "m2t", "m2ts", "m2p", "mts", "mp4", "m4v", "avi",
				"wmv", "wm", "vob", "divx", "div", "vdr" ];
		return id;
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
		return true;
	}
}
