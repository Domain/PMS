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
module net.pms.formats.ISO;

import net.pms.encoders.MEncoderVideo;
import net.pms.encoders.Player;

import java.util.ArrayList;

public class ISO : MPG {
	public static String[] ISO_EXTENSIONS = [ "iso", "img", /*"bin", "mdf", "nrg", "bwt", "cif","ccd", "vcd", "fcd"*/ ];

	/**
	 * {@inheritDoc} 
	 */
	override
	public Identifier getIdentifier() {
		return Identifier.ISO;
	}


	override
	public ArrayList/*<Class<? : Player>>*/ getProfiles() {
		ArrayList/*<Class<? : Player>>*/ list = new ArrayList/*<Class<? : Player>>*/();
		list.add(MEncoderVideo._class);
		return list;
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
	public bool ps3compatible() {
		return false;
	}

	/**
	 * {@inheritDoc}
	 */
	public String[] getId() {
		return ISO_EXTENSIONS;
	}
}
