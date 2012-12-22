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
module net.pms.dlna.Feed;

import com.sun.syndication.feed.synd.SyndCategory;
import com.sun.syndication.feed.synd.SyndEnclosure;
import com.sun.syndication.feed.synd.SyndEntry;
import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.io.SyndFeedInput;
import com.sun.syndication.io.XmlReader;
import org.apache.commons.lang.StringUtils;
import org.jdom.Content;
import org.jdom.Element;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * TODO: Change all instance variables to private. For backwards compatibility
 * with external plugin code the variables have all been marked as deprecated
 * instead of changed to private, but this will surely change in the future.
 * When everything has been changed to private, the deprecated note can be
 * removed.
 */
public class Feed : DLNAResource {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!Feed();

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	protected String name;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	protected String url;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	protected String tempItemTitle;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	protected String tempItemLink;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	protected String tempFeedLink;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	protected String tempCategory;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	protected String tempItemThumbURL;

	override
	public void resolve() {
		super.resolve();
		try {
			parse();
		} catch (Exception e) {
			logger.error("Error in parsing stream: " ~ url, e);
		}
	}

	public this(String name, String url, int type) {
		super(type);
		setUrl(url);
		setName(name);
	}

	public void parse() {
		SyndFeedInput input = new SyndFeedInput();
		byte b[] = downloadAndSendBinary(url);
		if (b !is null) {
			SyndFeed feed = input.build(new XmlReader(new ByteArrayInputStream(b)));
			setName(feed.getTitle());
			if (feed.getCategories() !is null && feed.getCategories().size() > 0) {
				SyndCategory category = cast(SyndCategory) feed.getCategories().get(0);
				setTempCategory(category.getName());
			}
			List/*<SyndEntry>*/ entries = feed.getEntries();
			foreach (SyndEntry entry ; entries) {
				setTempItemTitle(entry.getTitle());
				setTempItemLink(entry.getLink());
				setTempFeedLink(entry.getUri());
				setTempItemThumbURL(null);

				ArrayList/*<Element>*/ elements = cast(ArrayList/*<Element>*/) entry.getForeignMarkup();
				foreach (Element elt ; elements) {
					if ("group".equals(elt.getName()) && "media".equals(elt.getNamespacePrefix())) {
						List<Content> subElts = elt.getContent();
						foreach (Content subelt ; subElts) {
							if (cast(Element)subelt !is null ) {
								parseElement(cast(Element) subelt, false);
							}
						}
					}
					parseElement(elt, true);
				}
				List/*<SyndEnclosure>*/ enclosures = entry.getEnclosures();
				foreach (SyndEnclosure enc ; enclosures) {
					if (StringUtils.isNotBlank(enc.getUrl())) {
						setTempItemLink(enc.getUrl());
					}
				}
				manageItem();
			}
		}
		setLastModified(System.currentTimeMillis());
	}

	private void parseElement(Element elt, bool parseLink) {
		if ("content".equals(elt.getName()) && "media".equals(elt.getNamespacePrefix())) {
			if (parseLink) {
				setTempItemLink(elt.getAttribute("url").getValue());
			}
			List/*<Content>*/ subElts = elt.getContent();
			foreach (Content subelt ; subElts) {
				if (cast(Element)subelt !is null) {
					parseElement(cast(Element) subelt, false);
				}
			}
		}
		if ("thumbnail".equals(elt.getName()) && "media".equals(elt.getNamespacePrefix())
				&& getTempItemThumbURL() is null) {
			setTempItemThumbURL(elt.getAttribute("url").getValue());
		}
		if ("image".equals(elt.getName()) && "exInfo".equals(elt.getNamespacePrefix())
				&& getTempItemThumbURL() is null) {
			setTempItemThumbURL(elt.getValue());
		}
	}

	public InputStream getInputStream() {
		return null;
	}

	public String getName() {
		return name;
	}

	public bool isFolder() {
		return true;
	}

	public long length() {
		return 0;
	}

	// XXX unused
	deprecated
	public long lastModified() {
		return 0;
	}

	override
	public String getSystemName() {
		return url;
	}

	override
	public bool isValid() {
		return true;
	}

	protected void manageItem() {
		FeedItem fi = new FeedItem(getTempItemTitle(), getTempItemLink(), getTempItemThumbURL(), null, getSpecificType());
		addChild(fi);
	}

	override
	public bool isRefreshNeeded() {
	    return (System.currentTimeMillis() - getLastModified() > 3600000);
	}

	override
	public void doRefreshChildren() {
		try {
			getChildren().clear();
			parse();
		} catch (Exception e) {
			logger.error("Error in parsing stream: " ~ url, e);
		}
	}

	/**
	 * @return the url
	 * @since 1.50.0
	 */
	protected String getUrl() {
		return url;
	}

	/**
	 * @param url the url to set
	 * @since 1.50.0
	 */
	protected void setUrl(String url) {
		this.url = url;
	}

	/**
	 * @return the tempItemTitle
	 * @since 1.50.0
	 */
	protected String getTempItemTitle() {
		return tempItemTitle;
	}

	/**
	 * @param tempItemTitle the tempItemTitle to set
	 * @since 1.50.0
	 */
	protected void setTempItemTitle(String tempItemTitle) {
		this.tempItemTitle = tempItemTitle;
	}

	/**
	 * @return the tempItemLink
	 * @since 1.50.0
	 */
	protected String getTempItemLink() {
		return tempItemLink;
	}

	/**
	 * @param tempItemLink the tempItemLink to set
	 * @since 1.50.0
	 */
	protected void setTempItemLink(String tempItemLink) {
		this.tempItemLink = tempItemLink;
	}

	/**
	 * @return the tempFeedLink
	 * @since 1.50.0
	 */
	protected String getTempFeedLink() {
		return tempFeedLink;
	}

	/**
	 * @param tempFeedLink the tempFeedLink to set
	 * @since 1.50.0
	 */
	protected void setTempFeedLink(String tempFeedLink) {
		this.tempFeedLink = tempFeedLink;
	}

	/**
	 * @return the tempCategory
	 * @since 1.50.0
	 */
	protected String getTempCategory() {
		return tempCategory;
	}

	/**
	 * @param tempCategory the tempCategory to set
	 * @since 1.50.0
	 */
	protected void setTempCategory(String tempCategory) {
		this.tempCategory = tempCategory;
	}

	/**
	 * @return the tempItemThumbURL
	 * @since 1.50.0
	 */
	protected String getTempItemThumbURL() {
		return tempItemThumbURL;
	}

	/**
	 * @param tempItemThumbURL the tempItemThumbURL to set
	 * @since 1.50.0
	 */
	protected void setTempItemThumbURL(String tempItemThumbURL) {
		this.tempItemThumbURL = tempItemThumbURL;
	}

	/**
	 * @param name the name to set
	 * @since 1.50.0
	 */
	protected void setName(String name) {
		this.name = name;
	}
}
