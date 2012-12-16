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
module net.pms.dlna.ImagesFeed;

import net.pms.formats.Format;

public class ImagesFeed : Feed {
	override
	protected void manageItem() {
		// Picasa Web Albums Support
		if (getTempFeedLink() !is null && getTempCategory() !is null && getTempCategory().endsWith("user") && getUrl().toLowerCase().indexOf("picasaweb.google") > -1) {
			addChild(new ImagesFeed(getTempFeedLink().replace("data/entry/base", "data/feed/base")));
		} else {
			super.manageItem();
		}
	}

	public ImagesFeed(String url) {
		super("" + System.currentTimeMillis(), url, Format.IMAGE);
	}
}
