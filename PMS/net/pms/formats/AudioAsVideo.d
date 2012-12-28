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
module net.pms.formats.AudioAsVideo;

import net.pms.PMS;
import net.pms.encoders.Player;
import net.pms.encoders.TsMuxerAudio;

import java.util.ArrayList;

public class AudioAsVideo : MKV {
	/**
	 * {@inheritDoc} 
	 */
	override
	public Identifier getIdentifier() {
		return Identifier.AUDIO_AS_VIDEO;
	}

	override
	public ArrayList/*<Class<? : Player>>*/ getProfiles() {
		ArrayList/*<Class<? : Player>>*/ a = new ArrayList/*<Class<? : Player>>*/();
		PMS r = PMS.get();
		foreach (String engine ; PMS.getConfiguration().getEnginesAsList(r.getRegistry())) {
			if (engine.opEquals(TsMuxerAudio.ID)) {
				a.add(TsMuxerAudio._class);
			}
		}
		return a;
	}
}
