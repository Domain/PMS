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
module net.pms.dlna.FeedItem;

import java.io.IOException;
import java.io.InputStream;

public class FeedItem : DLNAResource {
	override
	protected String getThumbnailURL() {
		if (thumbURL is null) {
			return null;
		}
		return super.getThumbnailURL();
	}

	override
	public String getThumbnailContentType() {
		if (thumbURL !is null && thumbURL.toLowerCase().endsWith(".jpg")) {
			return JPEG_TYPEMIME;
		} else {
			return super.getThumbnailContentType();
		}
	}

	override
	public InputStream getThumbnailInputStream() throws IOException {
		return downloadAndSend(thumbURL, true);
	}
	private String title;
	private String itemURL;
	private String thumbURL;
	private long length;

	public FeedItem(String title, String itemURL, String thumbURL, DLNAMediaInfo media, int type) {
		super(type);
		this.title = title;
		this.itemURL = itemURL;
		this.thumbURL = thumbURL;
		this.setMedia(media);
	}

	public InputStream getInputStream() throws IOException {
		InputStream i = downloadAndSend(itemURL, true);
		if (i !is null) {
			length = i.available();
		}
		return i;
	}

	public String getName() {
		return title;
	}

	public bool isFolder() {
		return false;
	}

	public long length() {
		return length;
	}

	// XXX unused
	deprecated
	public long lastModified() {
		return 0;
	}

	override
	public void discoverChildren() {
	}

	override
	public String getSystemName() {
		return itemURL;
	}

	public void parse(String content) {
	}

	override
	public bool isValid() {
		checktype();
		return getFormat() !is null;
	}
}
