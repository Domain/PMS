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
module net.pms.dlna.DLNAResource;

import net.pms.Messages;
import net.pms.PMS;
import net.pms.configuration.FormatConfiguration;
import net.pms.configuration.RendererConfiguration;
import net.pms.dlna.virtual.TranscodeVirtualFolder;
import net.pms.dlna.virtual.VirtualFolder;
import net.pms.encoders.all;
import net.pms.external.AdditionalResourceFolderListener;
import net.pms.external.ExternalFactory;
import net.pms.external.ExternalListener;
import net.pms.external.StartStopListener;
import net.pms.formats.Format;
import net.pms.formats.FormatFactory;
import net.pms.io.OutputParams;
import net.pms.io.ProcessWrapper;
import net.pms.io.SizeLimitInputStream;
import net.pms.network.HTTPResource;
import net.pms.util.FileUtil;
import net.pms.util.ImagesUtil;
import net.pms.util.Iso639;
import net.pms.util.MpegUtil;
import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.all;
import java.net.URLEncoder;
import java.text.SimpleDateFormat;
import java.util.all;
//import java.util.concurrent.ArrayBlockingQueue;
//import java.util.concurrent.ThreadPoolExecutor;
//import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;

import net.pms.util.StringUtil : isBlank, isNotBlank, isEmpty, isNotEmpty;

/**
 * Represents any item that can be browsed via the UPNP ContentDirectory service.
 *
 * TODO: Change all instance variables to private. For backwards compatibility
 * with external plugin code the variables have all been marked as deprecated
 * instead of changed to private, but this will surely change in the future.
 * When everything has been changed to private, the deprecated note can be
 * removed.
 */
public abstract class DLNAResource : HTTPResource , Cloneable, Runnable {
	private immutable Map/*<String, Integer>*/ requestIdToRefcount = new HashMap/*<String, Integer>*/();
	private static const int STOP_PLAYING_DELAY = 4000;
	private static immutable Logger LOGGER = LoggerFactory.getLogger!DLNAResource();
	private static immutable SimpleDateFormat SDF_DATE = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US);

	protected static const int MAX_ARCHIVE_ENTRY_SIZE = 10000000;
	protected static const int MAX_ARCHIVE_SIZE_SEEK = 800000000;

	/**
	 * @deprecated This field will be removed. Use {@link net.pms.configuration.PmsConfiguration#getTranscodeFolderName()} instead.
	 */
	deprecated
	protected static immutable String TRANSCODE_FOLDER = Messages.getString("TranscodeVirtualFolder.0"); // localized #--TRANSCODE--#

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	protected int specificType;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	protected String id;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	protected DLNAResource parent;

	/**
	 * @deprecated This field will be removed. Use {@link #getFormat()} and
	 * {@link #setFormat(Format)} instead.
	 */
	deprecated
	protected Format ext;

	/**
	 * The format of this resource.
	 */
	private Format format;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	protected DLNAMediaInfo media;

	/**
	 * @deprecated Use {@link #getMediaAudio()} and {@link
	 * #setMediaAudio(DLNAMediaAudio)} to access this field.
	 */
	deprecated
	protected DLNAMediaAudio media_audio;

	/**
	 * @deprecated Use {@link #getMediaSubtitle()} and {@link
	 * #setMediaSubtitle(DLNAMediaSubtitle)} to access this field.
	 */
	deprecated
	protected DLNAMediaSubtitle media_subtitle;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	protected long lastmodified; // TODO make private and rename lastmodified -> lastModified

	/**
	 * Represents the transformation to be used to the file. If null, then
	 * @see Player
	 */
	private Player player;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	protected bool discovered = false;

	private ProcessWrapper externalProcess;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	protected bool srtFile;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	protected int updateId = 1;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	public static int systemUpdateId = 1;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	protected bool noName;

	private int nametruncate;
	private DLNAResource first;
	private DLNAResource second;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 *
	 * The time range for the file containing the start and end time in seconds.
	 */
	deprecated
	protected Range.Time splitRange = new Range.Time();

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	protected int splitTrack;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	protected String fakeParentId;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	// Ditlew - needs this in one of the derived classes
	deprecated
	protected RendererConfiguration defaultRenderer;

	private String dlnaspec;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	protected bool avisynth;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 */
	deprecated
	protected bool skipTranscode = false;

	private bool allChildrenAreFolders = true;
	private String dlnaOrgOpFlags;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 *
	 * List of children objects associated with this DLNAResource. This is only valid when the DLNAResource is of the container type.
	 */
	deprecated
	protected List/*<DLNAResource>*/ children;

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 *
	 * The numerical ID (1-based index) assigned to the last child of this folder. The next child is assigned this ID + 1.
	 */
	// FIXME should be lastChildId
	deprecated
	protected int lastChildrenId = 0; // XXX make private and rename lastChildrenId -> lastChildId

	/**
	 * @deprecated Use standard getter and setter to access this field.
	 *
	 * The last time refresh was called.
	 */
	deprecated
	protected long lastRefreshTime;

	/**
	 * Returns parent object, usually a folder type of resource. In the DLDI
	 * queries, the UPNP server needs to give out the parent container where
	 * the item is. The <i>parent</i> represents such a container.
	 *
	 * @return Parent object.
	 */
	public DLNAResource getParent() {
		return parent;
	}

	/**
	 * Set the parent object, usually a folder type of resource. In the DLDI
	 * queries, the UPNP server needs to give out the parent container where
	 * the item is. The <i>parent</i> represents such a container.

	 * @param parent Sets the parent object.
	 */
	public void setParent(DLNAResource parent) {
		this.parent = parent;
	}

	/**
	 * Returns the id of this resource based on the index in its parent
	 * container. Its main purpose is to be unique in the parent container.
	 *
	 * @return The id string.
	 * @since 1.50.0
	 */
	protected String getId() {
		return id;
	}

	/**
	 * Set the ID of this resource based on the index in its parent container.
	 * Its main purpose is to be unique in the parent container. The method is
	 * automatically called by addChildInternal, so most of the time it is not
	 * necessary to call it explicitly.
	 *
	 * @param id
	 * @since 1.50.0
	 * @see #addChildInternal(DLNAResource)
	 */
	protected void setId(String id) {
		this.id = id;
	}

	/**
	 * String representing this resource ID. This string is used by the UPNP
	 * ContentDirectory service. There is no hard spec on the actual numbering
	 * except for the root container that always has to be "0". In PMS the
	 * format used is <i>number($number)+</i>. A common client that expects a
	 * different format than the one used here is the XBox360. PMS translates
	 * the XBox360 queries on the fly. For more info, check
	 * http://www.mperfect.net/whsUpnp360/ .
	 *
	 * @return The resource id.
	 * @since 1.50.0
	 */
	public String getResourceId() {
		if (getId() is null) {
			return null;
		}

		if (getParent() !is null) {
			return getParent().getResourceId() ~ '$' ~ getId();
		} else {
			return getId();
		}
	}

	/**
	 * @see #setId(String)
	 * @param id
	 */
	protected void setIndexId(int id) {
		setId(Integer.toString(id));
	}

	/**
	 *
	 * @return the unique id which identifies the DLNAResource relative to its parent.
	 */
	public String getInternalId() {
		return getId();
	}

	/**
	 *
	 * @return true, if this contain can have a transcode folder
	 */
	public bool isTranscodeFolderAvailable() {
		return true;
	}

	/**Any {@link DLNAResource} needs to represent the container or item with a String.
	 * @return String to be showed in the UPNP client.
	 */
	public abstract String getName();

	public abstract String getSystemName();

	public abstract long length();

	// Ditlew
	public long length(RendererConfiguration mediaRenderer) {
		return length();
	}

	public abstract InputStream getInputStream();

	public abstract bool isFolder();

	public String getDlnaContentFeatures() {
		return (dlnaspec !is null ? (dlnaspec + ";") : "") ~ getDlnaOrgOpFlags() ~ ";DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000";
	}

	public DLNAResource getPrimaryResource() {
		return first;
	}

	public DLNAResource getSecondaryResource() {
		return second;
	}

	public String getFakeParentId() {
		return fakeParentId;
	}

	public void setFakeParentId(String fakeParentId) {
		this.fakeParentId = fakeParentId;
	}

	/**
	 * @return the fake parent id if specified, or the real parent id
	 */
	public String getParentId() {
		if (getFakeParentId() !is null) {
			return getFakeParentId();
		} else {
			if (getParent() !is null) {
				return getParent().getResourceId();
			} else {
				return "-1";
			}
		}
	}

	public this() {
		setSpecificType(Format.UNKNOWN);
		setChildren(new ArrayList/*<DLNAResource>*/());
		setUpdateId(1);
	}

	public this(int specificType) {
		this();
		setSpecificType(specificType);
	}

	/** Recursive function that searches through all of the children until it finds
	 * a {@link DLNAResource} that matches the name.<p> Only used by
	 * {@link net.pms.dlna.RootFolder#addWebFolder(File webConf)
	 * addWebFolder(File webConf)} while parsing the web.conf file.
	 * @param name String to be compared the name to.
	 * @return Returns a {@link DLNAResource} whose name matches the parameter name
	 * @see #getName()
	 */
	public DLNAResource searchByName(String name) {
		foreach (DLNAResource child ; getChildren()) {
			if (child.getName().opEquals(name)) {
				return child;
			}
		}
		return null;
	}

	/**
	 * @param renderer Renderer for which to check if file is supported.
	 * @return true if the given {@link net.pms.configuration.RendererConfiguration
	 *		RendererConfiguration} can understand type of media. Also returns true
	 *		if this DLNAResource is a container.
	 */
	public bool isCompatible(RendererConfiguration renderer) {
		return getFormat() is null
			|| getFormat().isUnknown()
			|| (getFormat().isVideo() && renderer.isVideoSupported())
			|| (getFormat().isAudio() && renderer.isAudioSupported())
			|| (getFormat().isImage() && renderer.isImageSupported());
	}

	/**Adds a new DLNAResource to the child list. Only useful if this object is of the container type.<P>
	 * TODO: (botijo) check what happens with the child object. This function can and will transform the child
	 * object. If the transcode option is set, the child item is converted to a container with the real
	 * item and the transcode option folder. There is also a parser in order to get the right name and type,
	 * I suppose. Is this the right place to be doing things like these?
	 * @param child DLNAResource to add to a container type.
	 */
	public void addChild(DLNAResource child) {
		// child may be null (spotted - via rootFolder.addChild() - in a misbehaving plugin
		if (child is null) {
			LOGGER.error("Attempt to add a null child to " ~ getName(), new NullPointerException("Invalid DLNA resource"));
			return;
		}

		child.setParent(this);

		if (getParent() !is null) {
			setDefaultRenderer(getParent().getDefaultRenderer());
		}

		try {
			if (child.isValid()) {
				LOGGER.trace("Adding " ~ child.getName() ~ " / class: " ~ child.getClass().getName());

				if (allChildrenAreFolders && !child.isFolder()) {
					allChildrenAreFolders = false;
				}

				addChildInternal(child);

				bool forceTranscodeV2 = false;
				bool parserV2 = child.getMedia() !is null && getDefaultRenderer() !is null && getDefaultRenderer().isMediaParserV2();

				if (parserV2) {
					// We already have useful info, just need to layout folders
					String mimeType = getDefaultRenderer().getFormatConfiguration().match(child.getMedia());

					if (mimeType !is null) {
						// This is streamable
						child.getMedia().setMimeType(mimeType.opEquals(FormatConfiguration.MIMETYPE_AUTO) ? child.getMedia().getMimeType() : mimeType);
					} else {
						// This is transcodable
						forceTranscodeV2 = true;
					}
				}

				if (child.getFormat() !is null) {
					setSkipTranscode(child.getFormat().skip(PMS.getConfiguration().getNoTranscode(), getDefaultRenderer() !is null ? getDefaultRenderer().getStreamedExtensions() : null));
				}

				if (child.getFormat() !is null && (child.getFormat().transcodable() || parserV2) && (child.getMedia() is null || parserV2)) {
					if (!parserV2) {
						child.setMedia(new DLNAMediaInfo());
					}

					// Try to determine a player to use for transcoding.
					Player player = null;

					// First, try to match a player based on the name of the DLNAResource
					// or its parent. If the name ends in "[unique player id]", that player
					// is preferred.
					String name = getName();

					foreach (Player p ; PlayerFactory.getAllPlayers()) {
						String end = "[" ~ p.id() ~ "]";

						if (name.endsWith(end)) {
							nametruncate = name.lastIndexOf(end);
							player = p;
							LOGGER.trace("Selecting player based on name end");
							break;
						} else if (getParent() !is null && getParent().getName().endsWith(end)) {
							getParent().nametruncate = getParent().getName().lastIndexOf(end);
							player = p;
							LOGGER.trace("Selecting player based on parent name end");
							break;
						}
					}

					// If no preferred player could be determined from the name, try to
					// match a player based on media information and format.
					if (player is null) {
						player = PlayerFactory.getPlayer(child);
					}

					if (player !is null && !allChildrenAreFolders) {
						bool forceTranscode = false;
						if (child.getFormat() !is null) {
							forceTranscode = child.getFormat().skip(PMS.getConfiguration().getForceTranscode(), getDefaultRenderer() !is null ? getDefaultRenderer().getTranscodedExtensions() : null);
						}

						bool hasEmbeddedSubs = false;

						if (child.getMedia() !is null) {
							foreach (DLNAMediaSubtitle s ; child.getMedia().getSubtitleTracksList()) {
								hasEmbeddedSubs = (hasEmbeddedSubs || s.isEmbedded());
							}
						}

						bool hasSubsToTranscode = false;

						if (!PMS.getConfiguration().isMencoderDisableSubs()) {
							hasSubsToTranscode = (PMS.getConfiguration().isAutoloadSubtitles() && child.isSrtFile()) || hasEmbeddedSubs;
						}

						bool isIncompatible = false;

						if (!child.getFormat().isCompatible(child.getMedia(),getDefaultRenderer())) {
							isIncompatible = true;
						}

						// Force transcoding if any of the following are true:
						// 1) The file is not supported by the renderer and SkipTranscode is not enabled for this extension
						// 2) ForceTranscode enabled for this extension
						// 3) FFmpeg support and the file is not PS3 compatible (XXX need to remove this?) and SkipTranscode is not enabled for this extension
						// 4) The file has embedded or external subs and SkipTranscode is not enabled for this extension
						if (forceTranscode || !isSkipTranscode() && (forceTranscodeV2 || isIncompatible || hasSubsToTranscode)) {
							child.setPlayer(player);
							LOGGER.trace("Switching " ~ child.getName() ~ " to player " ~ player.toString() ~ " for transcoding");
						}

						// Should the child be added to the transcode folder?
						if (child.getFormat().isVideo() && child.isTranscodeFolderAvailable()) {
							// true: create (and append) the #--TRANSCODE--# folder to this folder if it doesn't already exist
							VirtualFolder transcodeFolder = getTranscodeFolder(true);

							if (transcodeFolder !is null) {
								VirtualFolder fileTranscodeFolder = new FileTranscodeVirtualFolder(child.getName(), null);

								DLNAResource newChild = child.clone();
								newChild.setPlayer(player);
								newChild.setMedia(child.getMedia());
								fileTranscodeFolder.addChildInternal(newChild);
								LOGGER.trace("Duplicate " ~ child.getName() ~ " with player: " ~ player.toString());

								transcodeFolder.addChild(fileTranscodeFolder);
							}
						}

						foreach (ExternalListener listener ; ExternalFactory.getExternalListeners()) {
							if (cast(AdditionalResourceFolderListener)listener !is null) {
								try {
									(cast(AdditionalResourceFolderListener) listener).addAdditionalFolder(this, child);
								} catch (Throwable t) {
									LOGGER.error("Failed to add additional folder for listener of type: {}", listener.getClass(), t);
								}
							}
						}
					} else if (!child.getFormat().isCompatible(child.getMedia(),getDefaultRenderer()) && !child.isFolder()) {
						getChildren().remove(child);
					}
				}

				if (child.getFormat() !is null &&
					child.getFormat().getSecondaryFormat() !is null &&
					child.getMedia() !is null &&
					getDefaultRenderer() !is null &&
					getDefaultRenderer().supportsFormat(child.getFormat().getSecondaryFormat())
				) {
					DLNAResource newChild = child.clone();
					newChild.setFormat(newChild.getFormat().getSecondaryFormat());
					newChild.first = child;
					child.second = newChild;

					if (!newChild.getFormat().isCompatible(newChild.getMedia(), getDefaultRenderer())) {
						Player player = PlayerFactory.getPlayer(newChild);
						newChild.setPlayer(player);
					}

					if (child.getMedia() !is null && child.getMedia().isSecondaryFormatValid()) {
						addChild(newChild);
					}
				}
			}
		} catch (Throwable t) {
			LOGGER.error("Error adding child: %s", child.getName(), t);
			child.setParent(null);
			getChildren().remove(child);
		}
	}

	/**
	 * Return the transcode folder for this resource.
	 * If PMS is configured to hide transcode folders, null is returned.
	 * If no folder exists and the create argument is false, null is returned.
	 * If no folder exists and the create argument is true, a new transcode folder is created.
	 * This method is called on the parent frolder each time a child is added to that parent
	 * (via {@link addChild(DLNAResource)}.
	 * @param create
	 * @return the transcode virtual folder
	 */
	// XXX package-private: used by MapFile; should be protected?
	TranscodeVirtualFolder getTranscodeFolder(bool create) {
		if (!isTranscodeFolderAvailable()) {
			return null;
		}

		if (PMS.getConfiguration().getHideTranscodeEnabled()) {
			return null;
		}

		// search for transcode folder
		foreach (DLNAResource child ; getChildren()) {
			if (cast(TranscodeVirtualFolder)child !is null ) {
				return cast(TranscodeVirtualFolder) child;
			}
		}

		if (create) {
			TranscodeVirtualFolder transcodeFolder = new TranscodeVirtualFolder(null);
			addChildInternal(transcodeFolder);
			return transcodeFolder;
		}

		return null;
	}

	/**
	 * Adds the supplied DNLA resource to the internal list of child nodes,
	 * and sets the parent to the current node. Avoids the side-effects
	 * associated with the {@link addChild(DLNAResource)} method.
	 *
	 * @param child the DLNA resource to add to this node's list of children
	 */
	protected synchronized void addChildInternal(DLNAResource child) {
		if (child.getInternalId() !is null) {
			LOGGER.info(
				"Node (%s) already has an ID (%d), which is overriden now. The previous parent node was: %s",
				cast(Object[]) [
					child.getClass().getName(),
					child.getResourceId(),
					child.getParent()
				]
			);
		}

		getChildren().add(child);
		child.setParent(this);

		setLastChildId(getLastChildId() + 1);
		child.setIndexId(getLastChildId());
	}

	/**
	 * First thing it does it searches for an item matching the given objectID.
	 * If children is false, then it returns the found object as the only object in the list.
	 * TODO: (botijo) This function does a lot more than this!
	 * @param objectId ID to search for.
	 * @param returnChildren State if you want all the children in the returned list.
	 * @param start
	 * @param count
	 * @param renderer Renderer for which to do the actions.
	 * @return List of DLNAResource items.
	 * @throws IOException
	 */
	public synchronized List/*<DLNAResource>*/ getDLNAResources(String objectId, bool returnChildren, int start, int count, RendererConfiguration renderer) {
		ArrayList/*<DLNAResource>*/ resources = new ArrayList/*<DLNAResource>*/();
		DLNAResource resource = search(objectId, count, renderer);

		if (resource !is null) {
			resource.setDefaultRenderer(renderer);

			if (!returnChildren) {
				resources.add(resource);
				resource.refreshChildrenIfNeeded();
			} else {
				resource.discoverWithRenderer(renderer, count, true);

				if (count == 0) {
					count = resource.getChildren().size();
				}

				if (count > 0) {
					ArrayBlockingQueue/*<Runnable>*/ queue = new ArrayBlockingQueue/*<Runnable>*/(count);

					int parallel_thread_number = 3;
					if (cast(DVDISOFile)resource !is null) {
						parallel_thread_number = 1; // my DVD drive is dying wih 3 parallel threads
					}

					ThreadPoolExecutor tpe = new ThreadPoolExecutor(
						Math.min(count, parallel_thread_number),
						count,
						20,
						TimeUnit.SECONDS,
						queue
					);

					for (int i = start; i < start + count; i++) {
						if (i < resource.getChildren().size()) {
							immutable DLNAResource child = resource.getChildren().get(i);

							if (child !is null) {
								tpe.execute(child);
								resources.add(child);
							}
						}
					}

					try {
						tpe.shutdown();
						tpe.awaitTermination(20, TimeUnit.SECONDS);
					} catch (InterruptedException e) { }

					LOGGER.trace("End of analysis");
				}
			}
		}

		return resources;
	}

	protected void refreshChildrenIfNeeded() {
		if (isDiscovered() && isRefreshNeeded()) {
			refreshChildren();
			notifyRefresh();
		}
	}

	/**
	 * update the last refresh time.
	 */
	protected void notifyRefresh() {
		setLastRefreshTime(System.currentTimeMillis());
		setUpdateId(getUpdateId() + 1);
		setSystemUpdateId(getSystemUpdateId() + 1);
	}

	final protected void discoverWithRenderer(RendererConfiguration renderer, int count, bool forced) {
		// discover children if it hasn't been done already
		if (!isDiscovered()) {
			discoverChildren();
			bool ready = true;

			if (renderer.isMediaParserV2() && renderer.isDLNATreeHack()) {
				ready = analyzeChildren(count);
			} else {
				ready = analyzeChildren(-1);
			}

			if (!renderer.isMediaParserV2() || ready) {
				setDiscovered(true);
			}

			notifyRefresh();
		} else {
			// if forced, then call the old 'refreshChildren' method
			LOGGER.trace("discover %d refresh forced: %s", getResourceId(), forced);
			if (forced) {
				if (refreshChildren()) {
					notifyRefresh();
				}
			} else {
				// if not, then the regular isRefreshNeeded/doRefreshChildren pair.
				if (isRefreshNeeded()) {
					doRefreshChildren();
					notifyRefresh();
				}
			}
		}
	}

	override
	public void run() {
		if (first is null) {
			resolve();

			if (second !is null) {
				second.resolve();
			}
		}
	}

	/**Recursive function that searches for a given ID.
	 * @param searchId ID to search for.
	 * @param renderer
	 * @param count
	 * @return Item found, or null otherwise.
	 * @see #getId()
	 *
	 */
	public DLNAResource search(String searchId, int count, RendererConfiguration renderer) {
		if (getId() !is null && searchId !is null) {
			String[] indexPath = searchId.split("\\$", 2);

			if (getId().opEquals(indexPath[0])) {
				if (indexPath.length == 1 || indexPath[1].length() == 0) {
					return this;
				} else {
					discoverWithRenderer(renderer, count, false);

					foreach (DLNAResource file ; getChildren()) {
						DLNAResource found = file.search(indexPath[1], count, renderer);
						if (found !is null) {
							return found;
						}
					}
				}
			} else {
				return null;
			}
		}

		return null;
	}

	/**
	 * TODO: (botijo) What is the intention of this function? Looks like a prototype to be overloaded.
	 */
	public void discoverChildren() {
	}

	/**
	 * TODO: (botijo) What is the intention of this function? Looks like a prototype to be overloaded.
	 * @param count
	 * @return Returns true
	 */
	public bool analyzeChildren(int count) {
		return true;
	}

	/**
	 * Reload the list of children.
	 */
	public void doRefreshChildren() {
	}

	/**
	 * @return true, if the container is changed, so refresh is needed.
	 * This could be called a lot of times.
	 */
	public bool isRefreshNeeded() {
		return false;
	}

	/**
	 * This method gets called only for the browsed folder, and not for the
	 * parent folders. (And in the media library scan step too). Override in
	 * plugins when you do not want to implement proper change tracking, and
	 * you do not care if the hierarchy of nodes getting invalid between.
	 *
	 * @return True when a refresh is needed, false otherwise.
	 */
	public bool refreshChildren() {
		if (isRefreshNeeded()) {
			doRefreshChildren();
			return true;
		}
		return false;
	}

	protected void checktype() {
		if (getFormat() is null) {
			setFormat(FormatFactory.getAssociatedExtension(getSystemName()));
		}
		if (getFormat() !is null && getFormat().isUnknown()) {
			getFormat().setType(getSpecificType());
		}
	}

	/**
	 * Determine all properties for this DLNAResource that are relevant for playback
	 * or hierarchy traversal. This can be a costly operation, so when the method is
	 * finished the property <code>resolved</code> is set to <code>true</code>.
	 */
	public void resolve() {
	}

	// Ditlew
	/**
	 * Returns the DisplayName for the default renderer.
	 *
	 * @return The display name.
	 * @see #getDisplayName(RendererConfiguration)
	 */
	public String getDisplayName() {
		return getDisplayName(getDefaultRenderer());
	}

	/**
	 * Returns the string for this resource that will be displayed on the
	 * renderer. The name is formatted based on the renderer configuration
	 * setting "FileNameFormat" to contain the information of the resource.
	 * This allows the same resource to be displayed with different display
	 * names on different renderers.
	 * <p>
	 * The following formatting options are accepted:
	 *
	 * <table>
	 * <tr><th>Option</th><th>Description</th></tr>
	 * <tr><td>%A</td><td>Audio language full name</td></tr>
	 * <tr><td>%a</td><td>Audio language short name</td></tr>
	 * <tr><td>%b</td><td>Audio flavor</td></tr>
	 * <tr><td>%c</td><td>Audio codec</td></tr>
	 * <tr><td>%d</td><td>DVD track duration</td></tr>
	 * <tr><td>%E</td><td>Engine full name</td></tr>
	 * <tr><td>%e</td><td>Engine short name</td></tr>
	 * <tr><td>%F</td><td>File name with extension</td></tr>
	 * <tr><td>%f</td><td>File name without extension</td></tr>
	 * <tr><td>%S</td><td>Subtitle language full name</td></tr>
	 * <tr><td>%s</td><td>Subtitle language short name</td></tr>
	 * <tr><td>%t</td><td>Subtitle type</td></tr>
	 * <tr><td>%u</td><td>Subtitle flavor</td></tr>
	 * <tr><td>%x</td><td>External subtitles</td></tr>
	 * </table>
	 *
	 * @param mediaRenderer
	 *            Media Renderer for which to show information.
	 * @return String representing the item.
	 */
	public String getDisplayName(RendererConfiguration mediaRenderer) {

		// Chapter virtual folder ignores formats and only displays the start time
		if (getSplitRange().isEndLimitAvailable()) {
			return ">> " ~ DLNAMediaInfo.getDurationString(getSplitRange().getStart());
		}

		// Is this still relevant? The player name already contains "AviSynth"
		if (isAvisynth()) {
			return (getPlayer() !is null ? ("[" ~ getPlayer().name()) : "") ~ " + AviSynth]";
		}

		String result;
		String format;
		String audioLangFullName = "";
		String audioLangShortName = "";
		String audioFlavor = "";
		String audioCodec = "";
		String dvdTrackDuration = "";
		String engineFullName = "";
		String engineShortName = "";
		String filenameWithExtension = "";
		String filenameWithoutExtension = "";
		String subLangFullName = "";
		String subLangShortName = "";
		String subType = "";
		String subFlavor = "";
		String externalSubs = "";

		// Entries in the transcoding virtual folder get their audio details
		// set. So if this is the case, use the short file name format.
		bool useShortFormat = (getMediaAudio() !is null);

		// Determine the format
		if (mediaRenderer !is null) {
			if (useShortFormat) {
				format = mediaRenderer.getShortFileNameFormat();
			} else {
				format = mediaRenderer.getLongFileNameFormat();
			}
		} else {
			if (useShortFormat) {
				format = Messages.getString("DLNAResource.3");
			} else {
				format = Messages.getString("DLNAResource.4");
			}
		}

		// Handle file name
		if (isNoName()) {
			format = smartRemove(format, "%F", true);
			format = smartRemove(format, "%f", true);
		} else {
			filenameWithExtension = getName();
			filenameWithoutExtension = FileUtil.getFileNameWithoutExtension(filenameWithExtension);

			// Check if file extensions are configured to be hidden
			if (cast(RealFile)this !is null && PMS.getConfiguration().isHideExtensions() && !isFolder()) {
				filenameWithExtension = filenameWithoutExtension;
			}
		}

		// Handle engine name
		if (PMS.getConfiguration().isHideEngineNames()) {
			format = smartRemove(format, "%E", true);
			format = smartRemove(format, "%e", true);
		} else {
			if (getPlayer() !is null) {
				engineFullName = getPlayer().name();
				engineShortName = abbreviate(engineFullName);
			} else {
				if (isNoName()) {
					engineFullName = Messages.getString("DLNAResource.1");
					engineShortName = Messages.getString("DLNAResource.2");
				} else {
					format = smartRemove(format, "%E", true);
					format = smartRemove(format, "%e", true);
				}
			}
		}

		// Handle DVD track duration
		if (mediaRenderer !is null && mediaRenderer.isShowDVDTitleDuration()
				&& getMedia() !is null && getMedia().getDvdtrack() > 0) {
			dvdTrackDuration = getMedia().getDurationString();
		} else {
			format = smartRemove(format, "%d", false);
		}

		// Handle external subtitles
		if (isSrtFile() && (getMediaAudio() is null && getMediaSubtitle() is null)
				&& (getPlayer() is null || getPlayer().isExternalSubtitlesSupported())) {
			externalSubs = Messages.getString("DLNAResource.0");
		} else {
			format = smartRemove(format, "%x", false);
		}

		// Handle audio
		if (getMediaAudio() !is null) {
			audioCodec = getMediaAudio().getAudioCodec();
			audioLangFullName = getMediaAudio().getLangFullName();
			audioLangShortName = getMediaAudio().getLang();

			if ((getMediaAudio().getFlavor() !is null && mediaRenderer !is null && mediaRenderer.isShowAudioMetadata())) {
				audioFlavor = getMediaAudio().getFlavor();
			} else {
				format = smartRemove(format, "%b", false);
			}
		} else {
			format = smartRemove(format, "%b", false);
			format = smartRemove(format, "%c", false);
			format = smartRemove(format, "%A", true);
			format = smartRemove(format, "%a", true);
		}

		// Handle subtitle
		if (getMediaSubtitle() !is null && getMediaSubtitle().getId() != -1) {
			subType = getMediaSubtitle().getType().getDescription();
			subLangFullName = getMediaSubtitle().getLangFullName();
			subLangShortName = getMediaSubtitle().getLang();

			if (getMediaSubtitle().getFlavor() !is null && mediaRenderer !is null && mediaRenderer.isShowSubMetadata()) {
				subFlavor = getMediaSubtitle().getFlavor();
			} else {
				format = smartRemove(format, "%u", false);
			}
		} else {
			format = smartRemove(format, "%u", false);
			format = smartRemove(format, "%t", false);
			format = smartRemove(format, "%S", true);
			format = smartRemove(format, "%s", true);
		}

		// Finally, construct the result by replacing all tokens
		result = format;
		result = result.replaceAll("%A", audioLangFullName);
		result = result.replaceAll("%a", audioLangShortName);
		result = result.replaceAll("%b", audioFlavor);
		result = result.replaceAll("%c", audioCodec);
		result = result.replaceAll("%d", dvdTrackDuration);
		result = result.replaceAll("%E", engineFullName);
		result = result.replaceAll("%e", engineShortName);
		// XXX escape $ characters in the filename e.g. "The $10,000 Pyramid" -> "The \$10,000 Pyramid"
		// otherwise they confuse replaceAll:
		// http://www.ps3mediaserver.org/forum/viewtopic.php?f=3&t=15734
		// http://cephas.net/blog/2006/02/09/javalangillegalargumentexception-illegal-group-reference-replaceall-and-dollar-signs/
		result = result.replaceAll("%F", Matcher.quoteReplacement(filenameWithExtension));
		result = result.replaceAll("%f", Matcher.quoteReplacement(filenameWithoutExtension));
		result = result.replaceAll("%S", subLangFullName);
		result = result.replaceAll("%s", subLangShortName);
		result = result.replaceAll("%t", subType);
		result = result.replaceAll("%u", subFlavor);
		result = result.replaceAll("%x", externalSubs);
		result = result.trim();

		return result;
	}

	/**
	 * Removes the given token from the format string while trying to be smart
	 * about it. This means that optional surrounding braces, curly braces,
	 * brackets are removed as well, as are superfluous whitespace and
	 * separators. For example, removing "%E" from "%F - %d [%E] {%x}" results
	 * in "%F - %d {%x}". Removing "%d" from that will return "%F {%x}".
	 *
	 * @param format
	 *            The format string to remove the token from.
	 * @param token
	 *            The token to remove.
	 * @param aggressive
	 *            Search aggressively for surrounding braces, i.e. also delete
	 *            them if they are not directly adjacent to the token.
	 * @return The string with the token removed.
	 */
	private String smartRemove(String format, String token, bool aggressive) {
		if (token is null) {
			return format;
		}

		String result = format;

		if (aggressive) {
			// Allow other characters between the token and the braces
			result = result.replaceAll("\\([^\\(]*" ~ token ~ "[^\\)]*\\)", "");
			result = result.replaceAll("\\[[^\\[]*" ~ token ~ "[^\\]]*\\]", "");
			result = result.replaceAll("\\{[^\\{]*" ~ token ~ "[^\\}]*\\}", "");
			result = result.replaceAll("<[^<]*" ~ token ~ "[^>]*>", "");
		} else {
			// Braces have to be around the token
			result = result.replaceAll("[\\(\\[<\\{]" ~ token ~ "[\\)\\]>\\}]", "");
		}
		result = result.replaceAll("[-/,]\\s?" ~ token, "");
		result = result.replaceAll(token, "");

		// Collapse multiple spaces to a single space
		result = result.replaceAll("\\s+", " ");
		result = result.trim();

		return result;
	}

	/**Prototype for returning URLs.
	 * @return An empty URL
	 */
	protected String getFileURL() {
		return getURL("");
	}

	/**
	 * @return Returns a URL pointing to an image representing the item. If none is available, "thumbnail0000.png" is used.
	 */
	protected String getThumbnailURL() {
		StringBuilder sb = new StringBuilder();
		sb.append(PMS.get().getServer().getURL());
		sb.append("/images/");
		String id = null;

		if (getMediaAudio() !is null) {
			id = getMediaAudio().getLang();
		}

		if (getMediaSubtitle() !is null && getMediaSubtitle().getId() != -1) {
			id = getMediaSubtitle().getLang();
		}

		if ((getMediaSubtitle() !is null || getMediaAudio() !is null) && StringUtils.isBlank(id)) {
			id = DLNAMediaLang.UND;
		}

		if (id !is null) {
			String code = Iso639.getISO639_2Code(id.toLowerCase());
			sb.append("codes/").append(code).append(".png");
			return sb.toString();
		}

		if (isAvisynth()) {
			sb.append("avisynth-logo-gears-mod.png");
			return sb.toString();
		}

		return getURL("thumbnail0000");
	}

	/**
	 * @param prefix
	 * @return Returns a URL for a given media item. Not used for container types.
	 */
	protected String getURL(String prefix) {
		StringBuilder sb = new StringBuilder();
		sb.append(PMS.get().getServer().getURL());
		sb.append("/get/");
		sb.append(getResourceId()); //id
		sb.append("/");
		sb.append(prefix);
		sb.append(encode(getName()));

		return sb.toString();
	}

	/**Transforms a String to UTF-8.
	 * @param s
	 * @return Transformed string s in UTF-8 encoding.
	 */
	private static String encode(String s) {
		try {
			return URLEncoder.encode(s, "UTF-8");
		} catch (UnsupportedEncodingException e) {
			LOGGER._debug("Caught exception", e);
		}
		return "";
	}

	/**
	 * @return Number of children objects. This might be used in the DLDI response, as some renderers might
	 * not have enough memory to hold the list for all children.
	 */
	public int childrenNumber() {
		if (getChildren() is null) {
			return 0;
		}

		return getChildren().size();
	}

	/* (non-Javadoc)
	 * @see java.lang.Object#clone()
	 */
	override
	protected DLNAResource clone() {
		DLNAResource o = null;
		try {
			o = cast(DLNAResource) super.clone();
			o.setId(null);
		} catch (CloneNotSupportedException e) {
			LOGGER.error(null, e);
		}
		return o;
	}

	// this shouldn't be public
	deprecated
	public String getFlags() {
		return getDlnaOrgOpFlags();
	}

	// permit the renderer to seek by time, bytes or both
	private String getDlnaOrgOpFlags() {
		return "DLNA.ORG_OP=" ~ dlnaOrgOpFlags;
	}

	/**Returns an XML (DIDL) representation of the DLNA node. It gives a complete representation of the item, with as many tags as available.
	 * Recommendations as per UPNP specification are followed where possible.
	 * @param mediaRenderer Media Renderer for which to represent this information. Useful for some hacks.
	 * @return String representing the item. An example would start like this: {@code <container id="0$1" childCount="1" parentID="0" restricted="true">}
	 */
	public final String toString(RendererConfiguration mediaRenderer) {
		StringBuilder sb = new StringBuilder();

		if (isFolder()) {
			openTag(sb, "container");
		} else {
			openTag(sb, "item");
		}

		addAttribute(sb, "id", getResourceId());

		if (isFolder()) {
			if (!isDiscovered() && childrenNumber() == 0) {
				//  When a folder has not been scanned for resources, it will automatically have zero children.
				//  Some renderers like XBMC will assume a folder is empty when encountering childCount="0" and
				//  will not display the folder. By returning childCount="1" these renderers will still display
				//  the folder. When it is opened, its children will be discovered and childrenNumber() will be
				//  set to the right value.
				addAttribute(sb, "childCount", 1);
			} else {
				addAttribute(sb, "childCount", childrenNumber());
			}
		}

		addAttribute(sb, "parentID", getParentId());
		addAttribute(sb, "restricted", "true");
		endTag(sb);

		immutable DLNAMediaAudio firstAudioTrack = getMedia() !is null ? getMedia().getFirstAudioTrack() : null;
		if (firstAudioTrack !is null && StringUtils.isNotBlank(firstAudioTrack.getSongname())) {
			addXMLTagAndAttribute(
				sb,
				"dc:title",
				encodeXML(firstAudioTrack.getSongname() + (getPlayer() !is null && !PMS.getConfiguration().isHideEngineNames() ? (" [" + getPlayer().name() + "]") : ""))
			);
		} else { // Ditlew - org
			// Ditlew
			addXMLTagAndAttribute(
				sb,
				"dc:title",
				encodeXML((isFolder() || getPlayer() is null) ? getDisplayName() : mediaRenderer.getUseSameExtension(getDisplayName(mediaRenderer)))
			);
		}

		if (firstAudioTrack !is null) {
			if (StringUtils.isNotBlank(firstAudioTrack.getAlbum())) {
				addXMLTagAndAttribute(sb, "upnp:album", encodeXML(firstAudioTrack.getAlbum()));
			}

			if (StringUtils.isNotBlank(firstAudioTrack.getArtist())) {
				addXMLTagAndAttribute(sb, "upnp:artist", encodeXML(firstAudioTrack.getArtist()));
				addXMLTagAndAttribute(sb, "dc:creator", encodeXML(firstAudioTrack.getArtist()));
			}

			if (StringUtils.isNotBlank(firstAudioTrack.getGenre())) {
				addXMLTagAndAttribute(sb, "upnp:genre", encodeXML(firstAudioTrack.getGenre()));
			}

			if (firstAudioTrack.getTrack() > 0) {
				addXMLTagAndAttribute(sb, "upnp:originalTrackNumber", "" ~ firstAudioTrack.getTrack());
			}
		}

		if (!isFolder()) {
			int indexCount = 1;

			if (mediaRenderer.isDLNALocalizationRequired()) {
				indexCount = getDLNALocalesCount();
			}

			for (int c = 0; c < indexCount; c++) {
				openTag(sb, "res");

				// DLNA.ORG_OP flags
				//
				// Two bools (binary digits) which determine what transport operations the renderer is allowed to
				// perform (in the form of HTTP headers): the first digit allows the renderer to send
				// TimeSeekRange.DLNA.ORG (seek-by-time) headers; the second allows it to send RANGE (seek-by-byte)
				// headers.
				//
				// 00 - no seeking (or even pausing) allowed
				// 01 - seek by byte
				// 10 - seek by time
				// 11 - seek by both
				//
				// See here for an example of how these options can be mapped to keys on the renderer's controller:
				// http://www.ps3mediaserver.org/forum/viewtopic.php?f=2&t=2908&p=12550#p12550
				//
				// Note that seek-by-time is the preferred option (seek-by-byte is a fallback) but it requires a) support
				// by the renderer (via the SeekByTime renderer conf option) and either a) a file that's not being transcoded
				// or if it is, b) support by its transcode engine for seek-by-time.

				dlnaOrgOpFlags = "01";

				if (mediaRenderer.isSeekByTime()) {
					if (getPlayer() !is null) { // transcoded
						if (getPlayer().isTimeSeekable()) {
							// Some renderers - e.g. the PS3 and Panasonic TVs - behave erratically when
							// transcoding if we keep the default seek-by-byte permission on when permitting
							// seek-by-time: http://www.ps3mediaserver.org/forum/viewtopic.php?f=6&t=15841
							//
							// It's not clear if this is a bug in the DLNA libraries of these renderers or a bug
							// in PMS, but setting an option in the renderer conf that disables seek-by-byte when
							// we permit seek-by-time - e.g.:
							//
							//     SeekByTime = exclusive
							//
							// - works around it.
							if (mediaRenderer.isSeekByTimeExclusive()) {
								dlnaOrgOpFlags = "10";
							} else {
								dlnaOrgOpFlags = "11";
							}
						}
					} else { // streamed
						// chocolateboy 2012-11-25: seek-by-time used to be disabled here for the PS3
						// (the flag was left at the default seek-by-byte value) and only set to
						// seek-by-both for non-PS3 renderers. I can't reproduce with PS3 firmware 4.31
						// whatever (undocumented) issue led to the creation of this exception, so
						// it has been removed unless/until someone can reproduce it (e.g. with old
						// firmware)
						dlnaOrgOpFlags = "11";
					}
				}

				addAttribute(sb, "xmlns:dlna", "urn:schemas-dlna-org:metadata-1-0/");

				String mime = getRendererMimeType(mimeType(), mediaRenderer);
				if (mime is null) {
					mime = "video/mpeg";
				}

				if (mediaRenderer.isPS3()) { // XXX TO REMOVE, OR AT LEAST MAKE THIS GENERIC // whole extensions/mime-types mess to rethink anyway
					if (mime.opEquals("video/x-divx")) {
						dlnaspec = "DLNA.ORG_PN=AVI";
					} else if (mime.opEquals("video/x-ms-wmv") && getMedia() !is null && getMedia().getHeight() > 700) {
						dlnaspec = "DLNA.ORG_PN=WMVHIGH_PRO";
					}
				} else {
					if (mime.opEquals("video/mpeg")) {
						if (getPlayer() !is null) {
							// do we have some mpegts to offer ?
							bool mpegTsMux = TSMuxerVideo.ID.opEquals(getPlayer().id()) || VideoLanVideoStreaming.ID.opEquals(getPlayer().id());
							if (!mpegTsMux) {
								mpegTsMux = MEncoderVideo.ID.opEquals(getPlayer().id()) && mediaRenderer.isTranscodeToMPEGTSAC3();
							}

							if (mpegTsMux) {
								dlnaspec = getMedia().isH264() && !VideoLanVideoStreaming.ID.opEquals(getPlayer().id()) && getMedia().isMuxable(mediaRenderer) ?
									"DLNA.ORG_PN=AVC_TS_HD_24_AC3_ISO" :
									"DLNA.ORG_PN=" ~ getMPEG_TS_SD_EU_ISOLocalizedValue(c);
							} else {
								dlnaspec = "DLNA.ORG_PN=" ~ getMPEG_PS_PALLocalizedValue(c);
							}
						} else if (getMedia() !is null) {
							if (getMedia().isMpegTS()) {
								dlnaspec = getMedia().isH264() ? "DLNA.ORG_PN=AVC_TS_HD_50_AC3" : "DLNA.ORG_PN=" ~ getMPEG_TS_SD_EULocalizedValue(c);
							} else {
								dlnaspec = "DLNA.ORG_PN=" ~ getMPEG_PS_PALLocalizedValue(c);
							}
						} else {
							dlnaspec = "DLNA.ORG_PN=" ~ getMPEG_PS_PALLocalizedValue(c);
						}
					} else if (mime.opEquals("video/vnd.dlna.mpeg-tts")) {
						// patters - on Sony BDP m2ts clips aren't listed without this
						dlnaspec = "DLNA.ORG_PN=" ~ getMPEG_TS_SD_EULocalizedValue(c);
					} else if (mime.opEquals("image/jpeg")) {
						dlnaspec = "DLNA.ORG_PN=JPEG_LRG";
					} else if (mime.opEquals("audio/mpeg")) {
						dlnaspec = "DLNA.ORG_PN=MP3";
					} else if (mime.substring(0, 9).opEquals("audio/L16") || mime.opEquals("audio/wav")) {
						dlnaspec = "DLNA.ORG_PN=LPCM";
					}
				}

				if (dlnaspec !is null) {
					dlnaspec = "DLNA.ORG_PN=" ~ mediaRenderer.getDLNAPN(dlnaspec.substring(12));
				}

				if (!mediaRenderer.isDLNAOrgPNUsed()) {
					dlnaspec = null;
				}

				addAttribute(sb, "protocolInfo", "http-get:*:" ~ mime ~ ":" ~ (dlnaspec !is null ? (dlnaspec ~ ";") : "") ~ getDlnaOrgOpFlags());

				if (getFormat() !is null && getFormat().isVideo() && getMedia() !is null && getMedia().isMediaparsed()) {
					if (getPlayer() is null && getMedia() !is null) {
						addAttribute(sb, "size", getMedia().getSize());
					} else {
						long transcoded_size = mediaRenderer.getTranscodedSize();
						if (transcoded_size != 0) {
							addAttribute(sb, "size", transcoded_size);
						}
					}
					if (getMedia().getDuration() !is null) {
						if (getSplitRange().isEndLimitAvailable()) {
							addAttribute(sb, "duration", DLNAMediaInfo.getDurationString(getSplitRange().getDuration()));
						} else {
							addAttribute(sb, "duration", getMedia().getDurationString());
						}
					}

					if (getMedia().getResolution() !is null) {
						addAttribute(sb, "resolution", getMedia().getResolution());
					}

					addAttribute(sb, "bitrate", getMedia().getRealVideoBitrate());

					if (firstAudioTrack !is null) {
						if (firstAudioTrack.getAudioProperties().getNumberOfChannels() > 0) {
							addAttribute(sb, "nrAudioChannels", firstAudioTrack.getAudioProperties().getNumberOfChannels());
						}

						if (firstAudioTrack.getSampleFrequency() !is null) {
							addAttribute(sb, "sampleFrequency", firstAudioTrack.getSampleFrequency());
						}
					}
				} else if (getFormat() !is null && getFormat().isImage()) {
					if (getMedia() !is null && getMedia().isMediaparsed()) {
						addAttribute(sb, "size", getMedia().getSize());
						if (getMedia().getResolution() !is null) {
							addAttribute(sb, "resolution", getMedia().getResolution());
						}
					} else {
						addAttribute(sb, "size", length());
					}
				} else if (getFormat() !is null && getFormat().isAudio()) {
					if (getMedia() !is null && getMedia().isMediaparsed()) {
						addAttribute(sb, "bitrate", getMedia().getBitrate());
						if (getMedia().getDuration() !is null) {
							addAttribute(sb, "duration", DLNAMediaInfo.getDurationString(getMedia().getDuration()));
						}

						if (firstAudioTrack !is null && firstAudioTrack.getSampleFrequency() !is null) {
							addAttribute(sb, "sampleFrequency", firstAudioTrack.getSampleFrequency());
						}

						if (firstAudioTrack !is null) {
							addAttribute(sb, "nrAudioChannels", firstAudioTrack.getAudioProperties().getNumberOfChannels());
						}

						if (getPlayer() is null) {
							addAttribute(sb, "size", getMedia().getSize());
						} else {
							// calculate WAV size
							if (firstAudioTrack !is null) {
								int defaultFrequency = mediaRenderer.isTranscodeAudioTo441() ? 44100 : 48000;
								if (!PMS.getConfiguration().isAudioResample()) {
									try {
										// FIXME: Which exception could be thrown here?
										defaultFrequency = firstAudioTrack.getSampleRate();
									} catch (Exception e) {
										LOGGER._debug("Caught exception", e);
									}
								}

								int na = firstAudioTrack.getAudioProperties().getNumberOfChannels();
								if (na > 2) { // no 5.1 dump in mplayer
									na = 2;
								}

								int finalsize = cast(int) (getMedia().getDurationInSeconds() * defaultFrequency * 2 * na);
								LOGGER._debug("Calculated size: " ~ finalsize.toString());
								addAttribute(sb, "size", finalsize);
							}
						}
					} else {
						addAttribute(sb, "size", length());
					}
				} else {
					addAttribute(sb, "size", DLNAMediaInfo.TRANS_SIZE);
					addAttribute(sb, "duration", "09:59:59");
					addAttribute(sb, "bitrate", "1000000");
				}

				endTag(sb);
				sb.append(getFileURL());
				closeTag(sb, "res");
			}
		}

		String thumbURL = getThumbnailURL();
		if (!isFolder() && (getFormat() is null || (getFormat() !is null && thumbURL !is null))) {
			openTag(sb, "upnp:albumArtURI");
			addAttribute(sb, "xmlns:dlna", "urn:schemas-dlna-org:metadata-1-0/");

			if (getThumbnailContentType().opEquals(PNG_TYPEMIME) && !mediaRenderer.isForceJPGThumbnails()) {
				addAttribute(sb, "dlna:profileID", "PNG_TN");
			} else {
				addAttribute(sb, "dlna:profileID", "JPEG_TN");
			}

			endTag(sb);
			sb.append(thumbURL);
			closeTag(sb, "upnp:albumArtURI");
		}

		if ((isFolder() || mediaRenderer.isForceJPGThumbnails()) && thumbURL !is null) {
			openTag(sb, "res");

			if (getThumbnailContentType().opEquals(PNG_TYPEMIME) && !mediaRenderer.isForceJPGThumbnails()) {
				addAttribute(sb, "protocolInfo", "http-get:*:image/png:DLNA.ORG_PN=PNG_TN");
			} else {
				addAttribute(sb, "protocolInfo", "http-get:*:image/jpeg:DLNA.ORG_PN=JPEG_TN");
			}

			endTag(sb);
			sb.append(thumbURL);
			closeTag(sb, "res");
		}

		if (getLastModified() > 0) {
			addXMLTagAndAttribute(sb, "dc:date", SDF_DATE.format(new Date(getLastModified())));
		}

		String uclass = null;
		if (first !is null && getMedia() !is null && !getMedia().isSecondaryFormatValid()) {
			uclass = "dummy";
		} else {
			if (isFolder()) {
				uclass = "object.container.storageFolder";
				bool xbox = mediaRenderer.isXBOX();
				if (xbox && getFakeParentId() !is null && getFakeParentId().opEquals("7")) {
					uclass = "object.container.album.musicAlbum";
				} else if (xbox && getFakeParentId() !is null && getFakeParentId().opEquals("6")) {
					uclass = "object.container.person.musicArtist";
				} else if (xbox && getFakeParentId() !is null && getFakeParentId().opEquals("5")) {
					uclass = "object.container.genre.musicGenre";
				} else if (xbox && getFakeParentId() !is null && getFakeParentId().opEquals("F")) {
					uclass = "object.container.playlistContainer";
				}
			} else if (getFormat() !is null && getFormat().isVideo()) {
				uclass = "object.item.videoItem";
			} else if (getFormat() !is null && getFormat().isImage()) {
				uclass = "object.item.imageItem.photo";
			} else if (getFormat() !is null && getFormat().isAudio()) {
				uclass = "object.item.audioItem.musicTrack";
			} else {
				uclass = "object.item.videoItem";
			}
		}

		if (uclass !is null) {
			addXMLTagAndAttribute(sb, "upnp:class", uclass);
		}

		if (isFolder()) {
			closeTag(sb, "container");
		} else {
			closeTag(sb, "item");
		}

		return sb.toString();
	}

	private String getRequestId(String rendererId) {
		return String.format("%s|%x|%s", rendererId, hashCode(), getSystemName());
	}

	/**
	 * Plugin implementation. When this item is going to play, it will notify all the StartStopListener objects available.
	 * @see StartStopListener
	 */
	public void startPlaying(immutable String rendererId) {
		immutable String requestId = getRequestId(rendererId);
		synchronized (requestIdToRefcount) {
			Integer temp = requestIdToRefcount.get(requestId);
			if (temp is null) {
				temp = 0;
			}

			immutable Integer refCount = temp;
			requestIdToRefcount.put(requestId, refCount + 1);

			if (refCount == 0) {
				immutable DLNAResource self = this;
				Runnable r = new class() Runnable {
					override
					public void run() {
						LOGGER.info("renderer: {}, file: {}", rendererId, getSystemName());

						foreach (ExternalListener listener ; ExternalFactory.getExternalListeners()) {
							if (cast(StartStopListener)listener !is null) {
								// run these asynchronously for slow handlers (e.g. logging, scrobbling)
								Runnable fireStartStopEvent = dgRunnable( {
									try {
										(cast(StartStopListener) listener).nowPlaying(getMedia(), self);
									} catch (Throwable t) {
										LOGGER.error("Notification of startPlaying event failed for StartStopListener {}", listener.getClass(), t);
									}
								});
								(new Thread(fireStartStopEvent, "StartPlaying Event for " ~ listener.name())).start();
							}
						}
					}
				};

				(new Thread(r, "StartPlaying Event")).start();
			}
		}
	}

	/**
	 * Plugin implementation. When this item is going to stop playing, it will notify all the StartStopListener
	 * objects available.
	 * @see StartStopListener
	 */
	public void stopPlaying(immutable String rendererId) {
		immutable DLNAResource self = this;
		immutable String requestId = getRequestId(rendererId);
		Runnable defer = dgRunnable( {
			try {
				Thread.sleep(STOP_PLAYING_DELAY);
			} catch (InterruptedException e) {
				LOGGER.error("stopPlaying sleep interrupted", e);
			}

			synchronized (requestIdToRefcount) {
				immutable Integer refCount = requestIdToRefcount.get(requestId);
				assert(refCount !is null);
				assert(refCount > 0);
				requestIdToRefcount.put(requestId, refCount - 1);

				Runnable r = dgRunnable( {
					if (refCount == 1) {
						LOGGER.info("renderer: %d, file: %s", rendererId, getSystemName());
						PMS.get().getFrame().setStatusLine("");

						foreach (ExternalListener listener ; ExternalFactory.getExternalListeners()) {
							if (cast(StartStopListener)listener !is null) {
								// run these asynchronously for slow handlers (e.g. logging, scrobbling)
								Runnable fireStartStopEvent = dgRunnable( {
										try {
											(cast(StartStopListener) listener).donePlaying(getMedia(), self);
										} catch (Throwable t) {
											LOGGER.error("Notification of donePlaying event failed for StartStopListener %s", listener.getClass(), t);
										}
								});

								(new Thread(fireStartStopEvent, "StopPlaying Event for " ~ listener.name())).start();
							}
						}
					}
				});

				(new Thread(r, "StopPlaying Event")).start();
			}
		});

		(new Thread(defer, "StopPlaying Event Deferrer")).start();
	}

	/**
	 * Returns an InputStream of this DLNAResource that starts at a given time, if possible. Very useful if video chapters are being used.
	 * @param range
	 * @param mediarenderer
	 * @return The inputstream
	 * @throws IOException
	 */
	public InputStream getInputStream(Range range, RendererConfiguration mediarenderer) {
		LOGGER.trace("Asked stream chunk : " ~ range ~ " of " ~ getName() ~ " and player " ~ getPlayer());

		// shagrath: small fix, regression on chapters
		bool timeseek_auto = false;
		// Ditlew - WDTV Live
		// Ditlew - We convert byteoffset to timeoffset here. This needs the stream to be CBR!
		int cbr_video_bitrate = mediarenderer.getCBRVideoBitrate();
		long low = range.isByteRange() && range.isStartOffsetAvailable() ? range.asByteRange().getStart() : 0;
		long high = range.isByteRange() && range.isEndLimitAvailable() ? range.asByteRange().getEnd() : -1;
		Range.Time timeRange = range.createTimeRange();

		if (getPlayer() !is null && low > 0 && cbr_video_bitrate > 0) {
			int used_bit_rated = cast(int) ((cbr_video_bitrate + 256) * 1024 / 8 * 1.04); // 1.04 = container overhead
			if (low > used_bit_rated) {
				timeRange.setStart(cast(double) (low / (used_bit_rated)));
				low = 0;

				// WDTV Live - if set to TS it asks multiple times and ends by
				// asking for an invalid offset which kills MEncoder
				if (timeRange.getStartOrZero() > getMedia().getDurationInSeconds()) {
					return null;
				}

				// Should we rewind a little (in case our overhead isn't accurate enough)
				int rewind_secs = mediarenderer.getByteToTimeseekRewindSeconds();
				timeRange.rewindStart(rewind_secs);

				// shagrath:
				timeseek_auto = true;
			}
		}

		if (getPlayer() is null) {
			if (cast(IPushOutput)this !is null) {
				PipedOutputStream _out = new PipedOutputStream();
				InputStream fis = new PipedInputStream(_out);
				(cast(IPushOutput) this).push(_out);

				if (fis !is null) {
					if (low > 0) {
						fis.skip(low);
					}
					// http://www.ps3mediaserver.org/forum/viewtopic.php?f=11&t=12035
					fis = wrap(fis, high, low);
				}

				return fis;
			}

			InputStream fis = null;
			if (getFormat() !is null && getFormat().isImage() && getMedia() !is null && getMedia().getOrientation() > 1 && mediarenderer.isAutoRotateBasedOnExif()) {
				// seems it's a jpeg file with an orientation setting to take care of
				fis = ImagesUtil.getAutoRotateInputStreamImage(getInputStream(), getMedia().getOrientation());
				if (fis is null) { // error, let's return the original one
					fis = getInputStream();
				}
			} else {
				fis = getInputStream();
			}

			if (fis !is null) {
				if (low > 0) {
					fis.skip(low);
				}

				// http://www.ps3mediaserver.org/forum/viewtopic.php?f=11&t=12035
				fis = wrap(fis, high, low);

				if (timeRange.getStartOrZero() > 0 && cast(RealFile)this !is null) {
					fis.skip(MpegUtil.getPositionForTimeInMpeg((cast(RealFile) this).getFile(), cast(int) timeRange.getStartOrZero() ));
				}
			}

			return fis;
		} else {
			OutputParams params = new OutputParams(PMS.getConfiguration());
			params.aid = getMediaAudio();
			params.sid = getMediaSubtitle();
			params.mediaRenderer = mediarenderer;
			timeRange.limit(getSplitRange());
			params.timeseek = timeRange.getStartOrZero();
			params.timeend = timeRange.getEndOrZero();
			params.shift_scr = timeseek_auto;

			if (cast(IPushOutput)this !is null) {
				params.stdin = cast(IPushOutput) this;
			}

			if (externalProcess is null || externalProcess.isDestroyed()) {
				LOGGER.info("Starting transcode/remux of " ~ getName());

				externalProcess = getPlayer().launchTranscode(
					getSystemName(),
					this,
					getMedia(),
					params
				);

				if (params.waitbeforestart > 0) {
					LOGGER.trace("Sleeping for %d milliseconds", params.waitbeforestart);

					try {
						Thread.sleep(params.waitbeforestart);
					} catch (InterruptedException e) {
						LOGGER.error(null, e);
					}

					LOGGER.trace("Finished sleeping for " ~ params.waitbeforestart ~ " milliseconds");
				}
			} else if (params.timeseek > 0 && getMedia() !is null && getMedia().isMediaparsed()
					&& getMedia().getDurationInSeconds() > 0) {
				LOGGER._debug("Requesting time seek: " ~ params.timeseek.toString() ~ " seconds");
				params.minBufferSize = 1;

				Runnable r = dgRunnable( {
						externalProcess.stopProcess();
				});

				(new Thread(r, "External Process Stopper")).start();

				ProcessWrapper newExternalProcess = getPlayer().launchTranscode(
					getSystemName(),
					this,
					getMedia(),
					params
				);

				try {
					Thread.sleep(1000);
				} catch (InterruptedException e) {
					LOGGER.error(null, e);
				}

				if (newExternalProcess is null) {
					LOGGER.trace("External process instance is null... sounds not good");
				}

				externalProcess = newExternalProcess;
			}

			if (externalProcess is null) {
				return null;
			}

			InputStream fis = null;
			int timer = 0;
			while (fis is null && timer < 10) {
				fis = externalProcess.getInputStream(low);
				timer++;
				if (fis is null) {
					LOGGER.trace("External input stream instance is null... sounds not good, waiting 500ms");
					try {
						Thread.sleep(500);
					} catch (InterruptedException e) { }
				}
			}

			// fail fast: don't leave a process running indefinitely if it's
			// not producing output after params.waitbeforestart milliseconds + 5 seconds
			// this cleans up lingering MEncoder web video transcode processes that hang
			// instead of exiting
			if (fis is null && externalProcess !is null && !externalProcess.isDestroyed()) {
				Runnable r = dgRunnable( {
						LOGGER.trace("External input stream instance is null... stopping process");
						externalProcess.stopProcess();
				});

				(new Thread(r, "Hanging External Process Stopper")).start();
			}

			return fis;
		}
	}

	/**
	 * Wrap an {@link InputStream} in a {@link SizeLimitInputStream} that sets a
	 * limit to the maximum number of bytes to be read from the original input
	 * stream. The number of bytes is determined by the high and low value
	 * (bytes = high - low). If the high value is less than the low value, the
	 * input stream is not wrapped and returned as is.
	 *
	 * @param input
	 *            The input stream to wrap.
	 * @param high
	 *            The high value.
	 * @param low
	 *            The low value.
	 * @return The resulting input stream.
	 */
	private InputStream wrap(InputStream input, long high, long low) {
		if (input !is null && high > low) {
			long bytes = (high - (low < 0 ? 0 : low)) + 1;
			LOGGER.trace("Using size-limiting stream (" ~ bytes.toString() ~ " bytes)");
			return new SizeLimitInputStream(input, bytes);
		}
		return input;
	}

	public String mimeType() {
		if (getPlayer() !is null) {
			return getPlayer().mimeType();
		} else if (getMedia() !is null && getMedia().isMediaparsed()) {
			return getMedia().getMimeType();
		} else if (getFormat() !is null) {
			return getFormat().mimeType();
		} else {
			return getDefaultMimeType(getSpecificType());
		}
	}

	/**
	 * Prototype function. Original comment: need to override if some thumbnail work is to be done when mediaparserv2 enabled
	 */
	public void checkThumbnail() {
		// need to override if some thumbnail work is to be done when mediaparserv2 enabled
	}

	/**
	 * Checks if a thumbnail exists, and, if not, generates one (if possible).
	 * Called from Request/RequestV2 in response to thumbnail requests e.g. HEAD /get/0$1$0$42$3/thumbnail0000%5BExample.mkv
	 * Calls DLNAMediaInfo.generateThumbnail, which in turn calls DLNAMediaInfo.parse.
	 *
	 * @param input InputFile to check or generate the thumbnail from.
	 */
	protected void checkThumbnail(InputFile inputFile) {
		if (getMedia() !is null && !getMedia().isThumbready() && PMS.getConfiguration().isThumbnailGenerationEnabled()) {
			getMedia().setThumbready(true);
			getMedia().generateThumbnail(inputFile, getFormat(), getType());

			if (getMedia().getThumb() !is null && PMS.getConfiguration().getUseCache() && inputFile.getFile() !is null) {
				PMS.get().getDatabase().updateThumbnail(inputFile.getFile().getAbsolutePath(), inputFile.getFile().lastModified(), getType(), getMedia());
			}
		}
	}

	/** Returns the input stream for this resource's thumbnail
	 * (or a default image if a thumbnail can't be found).
	 * Typically overridden by a subclass.
	 * @return The InputStream
	 * @throws IOException
	 */
	public InputStream getThumbnailInputStream() {
		return getResourceInputStream("images/thumbnail-256.png");
	}

	public String getThumbnailContentType() {
		return HTTPResource.JPEG_TYPEMIME;
	}

	public int getType() {
		if (getFormat() !is null) {
			return getFormat().getType();
		} else {
			return Format.UNKNOWN;
		}
	}

	/**Prototype function.
	 * @return true if child can be added to other folder.
	 * @see #addChild(DLNAResource)
	 */
	public abstract bool isValid();

	public bool allowScan() {
		return false;
	}

	/* (non-Javadoc)
	 * @see java.lang.Object#toString()
	 */
	override
	public String toString() {
		return this.getClass().getSimpleName() ~ " [id=" ~ getId() ~ ", name=" ~ getName() ~ ", full path=" ~ getResourceId() ~ ", ext=" ~ getFormat() ~ ", discovered=" ~ isDiscovered() ~ "]";
	}

	/**
	 * Returns the specific type of resource. Valid types are defined in {@link Format}.
	 *
	 * @return The specific type
	 */
	protected int getSpecificType() {
		return specificType;
	}

	/**
	 * Set the specific type of this resource. Valid types are defined in {@link Format}.
	 * @param specificType The specific type to set.
	 */
	protected void setSpecificType(int specificType) {
		this.specificType = specificType;
	}

	/**
	 * Returns the {@link Format} of this resource, which defines its capabilities.
	 *
	 * @return The format of this resource.
	 */
	public Format getFormat() {
		return format;
	}

	/**
	 * Sets the {@link Format} of this resource, thereby defining its capabilities.
	 *
	 * @param format The format to set.
	 */
	protected void setFormat(Format format) {
		this.format = format;

		// Set deprecated variable for backwards compatibility
		ext = format;
	}

	/**
	 * @deprecated Use {@link #getFormat()} instead.
	 *
	 * @return The format of this resource.
	 */
	deprecated
	public Format getExt() {
		return getFormat();
	}

	/**
	 * @deprecated Use {@link #setFormat(Format)} instead.
	 *
	 * @param format The format to set.
	 */
	deprecated
	protected void setExt(Format format) {
		setFormat(format);
	}

	/**
	 * Returns the {@link DLNAMediaInfo} object for this resource, containing the
	 * specifics of this resource, e.g. the duration.
	 *
	 * @return The object containing detailed information.
	 */
	public DLNAMediaInfo getMedia() {
		return media;
	}

	/**
	 * Sets the the {@link DLNAMediaInfo} object that contains all specifics for
	 * this resource.
	 *
	 * @param media The object containing detailed information.
	 * @since 1.50.0
	 */
	protected void setMedia(DLNAMediaInfo media) {
		this.media = media;
	}

	/**
	 * Returns the {@link DLNAMediaAudio} object for this resource that contains
	 * the audio specifics. A resource can have many audio tracks, this method
	 * returns the one that should be played.
	 *
	 * @return The audio object containing detailed information.
	 * @since 1.50.0
	 */
	public DLNAMediaAudio getMediaAudio() {
		return media_audio;
	}

	/**
	 * Sets the {@link DLNAMediaAudio} object for this resource that contains
	 * the audio specifics. A resource can have many audio tracks, this method
	 * determines the one that should be played.
	 *
	 * @param mediaAudio The audio object containing detailed information.
	 * @since 1.50.0
	 */
	protected void setMediaAudio(DLNAMediaAudio mediaAudio) {
		this.media_audio = mediaAudio;
	}

	/**
	 * Returns the {@link DLNAMediaSubtitle} object for this resource that
	 * contains the specifics for the subtitles. A resource can have many
	 * subtitles, this method returns the one that should be displayed.
	 *
	 * @return The subtitle object containing detailed information.
	 * @since 1.50.0
	 */
	public DLNAMediaSubtitle getMediaSubtitle() {
		return media_subtitle;
	}

	/**
	 * Sets the {@link DLNAMediaSubtitle} object for this resource that
	 * contains the specifics for the subtitles. A resource can have many
	 * subtitles, this method determines the one that should be used.
	 *
	 * @param mediaSubtitle The subtitle object containing detailed information.
	 * @since 1.50.0
	 */
	protected void setMediaSubtitle(DLNAMediaSubtitle mediaSubtitle) {
		this.media_subtitle = mediaSubtitle;
	}

	/**
	 * @deprecated Use {@link #getLastModified()} instead.
	 *
	 * Returns the timestamp at which this resource was last modified.
	 *
	 * @return The timestamp.
	 */
	deprecated
	public long getLastmodified() {
		return getLastModified();
	}

	/**
	 * Returns the timestamp at which this resource was last modified.
	 *
	 * @return The timestamp.
	 * @since 1.71.0
	 */
	public long getLastModified() {
		return lastmodified; // TODO rename lastmodified -> lastModified
	}

	/**
	 * @deprecated Use {@link #setLastModified()} instead.
	 *
	 * Sets the timestamp at which this resource was last modified.
	 *
	 * @param lastModified The timestamp to set.
	 * @since 1.50.0
	 */
	deprecated
	protected void setLastmodified(long lastModified) {
		setLastModified(lastModified);
	}

	/**
	 * Sets the timestamp at which this resource was last modified.
	 *
	 * @param lastModified The timestamp to set.
	 * @since 1.71.0
	 */
	protected void setLastModified(long lastModified) {
		this.lastmodified = lastModified; // TODO rename lastmodified -> lastModified
	}

	/**
	 * Returns the {@link Player} object that is used to encode this resource
	 * for the renderer. Can be null.
	 *
	 * @return The player object.
	 */
	public Player getPlayer() {
		return player;
	}

	/**
	 * Sets the {@link Player} object that is to be used to encode this
	 * resource for the renderer. The player object can be null.
	 *
	 * @param player The player object to set.
	 * @since 1.50.0
	 */
	protected void setPlayer(Player player) {
		this.player = player;
	}

	/**
	 * Returns true when the details of this resource have already been
	 * investigated. This helps is not doing the same work twice.
	 *
	 * @return True if discovered, false otherwise.
	 */
	public bool isDiscovered() {
		return discovered;
	}

	/**
	 * Set to true when the details of this resource have already been
	 * investigated. This helps is not doing the same work twice.
	 *
	 * @param discovered Set to true if this resource is discovered,
	 * 			false otherwise.
	 * @since 1.50.0
	 */
	protected void setDiscovered(bool discovered) {
		this.discovered = discovered;
	}

	/**
	 * Returns true if this resource has subtitles in a file.
	 *
	 * @return the srtFile
	 * @since 1.50.0
	 */
	protected bool isSrtFile() {
		return srtFile;
	}

	/**
	 * Set to true if this resource has subtitles in a file.
	 *
	 * @param srtFile the srtFile to set
	 * @since 1.50.0
	 */
	protected void setSrtFile(bool srtFile) {
		this.srtFile = srtFile;
	}

	/**
	 * Returns the update counter for this resource. When the resource needs
	 * to be refreshed, its counter is updated.
	 *
	 * @return The update counter.
	 * @see #notifyRefresh()
	 */
	public int getUpdateId() {
		return updateId;
	}

	/**
	 * Sets the update counter for this resource. When the resource needs
	 * to be refreshed, its counter should be updated.
	 *
	 * @param updateId The counter value to set.
	 * @since 1.50.0
	 */
	protected void setUpdateId(int updateId) {
		this.updateId = updateId;
	}

	/**
	 * Returns the update counter for all resources. When all resources need
	 * to be refreshed, this counter is updated.
	 *
	 * @return The system update counter.
	 * @since 1.50.0
	 */
	public static int getSystemUpdateId() {
		return systemUpdateId;
	}

	/**
	 * Sets the update counter for all resources. When all resources need
	 * to be refreshed, this counter should be updated.
	 *
	 * @param systemUpdateId The system update counter to set.
	 * @since 1.50.0
	 */
	public static void setSystemUpdateId(int systemUpdateId) {
		DLNAResource.systemUpdateId = systemUpdateId;
	}

	/**
	 * Returns whether or not this is a nameless resource.
	 *
	 * @return True if the resource is nameless.
	 */
	public bool isNoName() {
		return noName;
	}

	/**
	 * Sets whether or not this is a nameless resource. This is particularly
	 * useful in the virtual TRANSCODE folder for a file, where the same file
	 * is copied many times with different audio and subtitle settings. In that
	 * case the name of the file becomes irrelevant and only the settings
	 * need to be shown.
	 *
	 * @param noName Set to true if the resource is nameless.
	 * @since 1.50.0
	 */
	protected void setNoName(bool noName) {
		this.noName = noName;
	}

	/**
	 * Returns the from - to time range for this resource.
	 *
	 * @return The time range.
	 */
	public Range.Time getSplitRange() {
		return splitRange;
	}

	/**
	 * Sets the from - to time range for this resource.
	 *
	 * @param splitRange The time range to set.
	 * @since 1.50.0
	 */
	protected void setSplitRange(Range.Time splitRange) {
		this.splitRange = splitRange;
	}

	/**
	 * Returns the number of the track to split from this resource.
	 *
	 * @return the splitTrack
	 * @since 1.50.0
	 */
	protected int getSplitTrack() {
		return splitTrack;
	}

	/**
	 * Sets the number of the track from this resource to split.
	 *
	 * @param splitTrack The track number.
	 * @since 1.50.0
	 */
	protected void setSplitTrack(int splitTrack) {
		this.splitTrack = splitTrack;
	}

	/**
	 * Returns the default renderer configuration for this resource.
	 *
	 * @return The default renderer configuration.
	 * @since 1.50.0
	 */
	protected RendererConfiguration getDefaultRenderer() {
		return defaultRenderer;
	}

	/**
	 * Sets the default renderer configuration for this resource.
	 *
	 * @param defaultRenderer The default renderer configuration to set.
	 * @since 1.50.0
	 */
	protected void setDefaultRenderer(RendererConfiguration defaultRenderer) {
		this.defaultRenderer = defaultRenderer;
	}

	/**
	 * Returns whether or not this resource is handled by Avisynth.
	 *
	 * @return True if handled by Avisynth, otherwise false.
	 * @since 1.50.0
	 */
	protected bool isAvisynth() {
		return avisynth;
	}

	/**
	 * Sets whether or not this resource is handled by Avisynth.
	 *
	 * @param avisynth Set to true if handled by Avisyth, otherwise false.
	 * @since 1.50.0
	 */
	protected void setAvisynth(bool avisynth) {
		this.avisynth = avisynth;
	}

	/**
	 * Returns true if transcoding should be skipped for this resource.
	 *
	 * @return True if transcoding should be skipped, false otherwise.
	 * @since 1.50.0
	 */
	protected bool isSkipTranscode() {
		return skipTranscode;
	}

	/**
	 * Set to true if transcoding should be skipped for this resource.
	 *
	 * @param skipTranscode Set to true if trancoding should be skipped, false
	 * 			otherwise.
	 * @since 1.50.0
	 */
	protected void setSkipTranscode(bool skipTranscode) {
		this.skipTranscode = skipTranscode;
	}

	/**
	 * Returns the list of children for this resource.
	 *
	 * @return List of children objects.
	 */
	public List/*<DLNAResource>*/ getChildren() {
		return children;
	}

	/**
	 * Sets the list of children for this resource.
	 *
	 * @param children The list of children to set.
	 * @since 1.50.0
	 */
	protected void setChildren(List/*<DLNAResource>*/ children) {
		this.children = children;
	}

	/**
	 * @deprecated use {@link #getLastChildId()} instead.
	 */
	deprecated
	protected int getLastChildrenId() {
		return getLastChildId();
	}

	/**
	 * Returns the numerical ID of the last child added.
	 *
	 * @return The ID.
	 * @since 1.80.0
	 */
	protected int getLastChildId() {
		return lastChildrenId;
	}

	/**
	 * @deprecated use {@link #setLastChildId(int)} instead.
	 */
	protected void setLastChildrenId(int lastChildId) {
		setLastChildId(lastChildId);
	}

	/**
	 * Sets the numerical ID of the last child added.
	 *
	 * @param lastChildId The ID to set.
	 * @since 1.80.0
	 */
	protected void setLastChildId(int lastChildId) {
		this.lastChildrenId = lastChildId;
	}

	/**
	 * Returns the timestamp when this resource was last refreshed.
	 *
	 * @return The timestamp.
	 */
	long getLastRefreshTime() {
		return lastRefreshTime;
	}

	/**
	 * Sets the timestamp when this resource was last refreshed.
	 *
	 * @param lastRefreshTime The timestamp to set.
	 * @since 1.50.0
	 */
	protected void setLastRefreshTime(long lastRefreshTime) {
		this.lastRefreshTime = lastRefreshTime;
	}
}
