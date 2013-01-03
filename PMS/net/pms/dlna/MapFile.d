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
module net.pms.dlna.MapFile;

import net.pms.PMS;
import net.pms.configuration.MapFileConfiguration;
import net.pms.dlna.virtual.TranscodeVirtualFolder;
import net.pms.dlna.virtual.VirtualFolder;
import net.pms.formats.FormatFactory;
import net.pms.network.HTTPResource;
import net.pms.util.NaturalComparator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.lang.exceptions;
import java.io.InputStream;
import java.text.Collator;
import java.util.all;

/**
 * TODO: Change all instance variables to private. For backwards compatibility
 * with external plugin code the variables have all been marked as deprecated
 * instead of changed to private, but this will surely change in the future.
 * When everything has been changed to private, the deprecated note can be
 * removed.
 */
public class MapFile : DLNAResource {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!MapFile();
	private List/*<File>*/ discoverable;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public File potentialCover;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	protected MapFileConfiguration conf;

	private static immutable Collator collator;

	static this() {
		collator = Collator.getInstance();
		collator.setStrength(Collator.PRIMARY);
	}

	public this() {
		setConf(new MapFileConfiguration());
		setLastModified(0);
	}

	public this(MapFileConfiguration conf) {
		setConf(conf);
		setLastModified(0);
	}

	private bool isFileRelevant(File f) {
		String fileName = f.getName().toLowerCase();
		return (PMS.getConfiguration().isArchiveBrowsing() && (fileName.endsWith(".zip") || fileName.endsWith(".cbz")
			|| fileName.endsWith(".rar") || fileName.endsWith(".cbr")))
			|| fileName.endsWith(".iso") || fileName.endsWith(".img")
			|| fileName.endsWith(".m3u") || fileName.endsWith(".m3u8") || fileName.endsWith(".pls") || fileName.endsWith(".cue");
	}

	private bool isFolderRelevant(File f) {
		bool isRelevant = false;

		if (f.isDirectory() && PMS.getConfiguration().isHideEmptyFolders()) {
			File[] children = f.listFiles();

			// listFiles() returns null if "this abstract pathname does not denote a directory, or if an I/O error occurs".
			// in this case (since we've already confirmed that it's a directory), this seems to mean the directory is non-readable
			// http://www.ps3mediaserver.org/forum/viewtopic.php?f=6&t=15135
			// http://stackoverflow.com/questions/3228147/retrieving-the-underlying-error-when-file-listfiles-return-null
			if (children is null) {
				LOGGER.warn("Can't list files in non-readable directory: %s", f.getAbsolutePath());
			} else {
				foreach (File child ; children) {
					if (child.isFile()) {
						if (FormatFactory.getAssociatedExtension(child.getName()) !is null || isFileRelevant(child)) {
							isRelevant = true;
							break;
						}
					} else {
						if (isFolderRelevant(child)) {
							isRelevant = true;
							break;
						}
					}
				}
			}
		}

		return isRelevant;
	}

	private void manageFile(File f) {
		if (f.isFile() || f.isDirectory()) {
			String lcFilename = f.getName().toLowerCase();

			if (!f.isHidden()) {
				if (PMS.getConfiguration().isArchiveBrowsing() && (lcFilename.endsWith(".zip") || lcFilename.endsWith(".cbz"))) {
					addChild(new ZippedFile(f));
				} else if (PMS.getConfiguration().isArchiveBrowsing() && (lcFilename.endsWith(".rar") || lcFilename.endsWith(".cbr"))) {
					addChild(new RarredFile(f));
				} else if ((lcFilename.endsWith(".iso") || lcFilename.endsWith(".img")) || (f.isDirectory() && f.getName().toUpperCase().opEquals("VIDEO_TS"))) {
					addChild(new DVDISOFile(f));
				} else if (lcFilename.endsWith(".m3u") || lcFilename.endsWith(".m3u8") || lcFilename.endsWith(".pls")) {
					addChild(new PlaylistFolder(f));
				} else if (lcFilename.endsWith(".cue")) {
					addChild(new CueFolder(f));
				} else {
					/* Optionally ignore empty directories */
					if (f.isDirectory() && PMS.getConfiguration().isHideEmptyFolders() && !isFolderRelevant(f)) {
						LOGGER._debug("Ignoring empty/non-relevant directory: " ~ f.getName());
					} else { // Otherwise add the file
						addChild(new RealFile(f));
					}
				}
			}

			// FIXME this causes folder thumbnails to take precedence over file thumbnails
			if (f.isFile()) {
				if (lcFilename.opEquals("folder.jpg") || lcFilename.opEquals("folder.png") || (lcFilename.contains("albumart") && lcFilename.endsWith(".jpg"))) {
					setPotentialCover(f);
				}
			}
		}
	}

	private List/*<File>*/ getFileList() {
		List/*<File>*/ _out = new ArrayList/*<File>*/();

		foreach (File file ; this.conf.getFiles()) {
			if (file !is null && file.isDirectory()) {
				if (file.canRead()) {
					File[] files = file.listFiles();

					if (files is null) {
						LOGGER.warn("Can't read files from directory: %s", file.getAbsolutePath());
					} else {
						_out.addAll(Arrays.asList(files));
					}
				} else {
					LOGGER.warn("Can't read directory: %s", file.getAbsolutePath());
				}
			}
		}

		return _out;
	}

	override
	public bool isValid() {
		return true;
	}

	override
	public bool analyzeChildren(int count) {
		int currentChildrenCount = getChildren().size();
		int vfolder = 0;

		while (((getChildren().size() - currentChildrenCount) < count) || (count == -1)) {
			if (vfolder < getConf().getChildren().size()) {
				addChild(new MapFile(getConf().getChildren().get(vfolder)));
				++vfolder;
			} else {
				if (discoverable.isEmpty()) {
					break;
				}

				manageFile(discoverable.remove(0));
			}
		}

		return discoverable.isEmpty();
	}

	override
	public void discoverChildren() {
		super.discoverChildren();

		if (discoverable is null) {
			discoverable = new ArrayList/*<File>*/();
		} else {
			return;
		}

		List/*<File>*/ files = getFileList();

		switch (PMS.getConfiguration().getSortMethod()) {
			case 4: // Locale-sensitive natural sort
				Collections.sort(files, new class() Comparator/*<File>*/ {
					public int compare(File f1, File f2) {
						return NaturalComparator.compareNatural(collator, f1.getName(), f2.getName());
					}
				});
				break;
			case 3: // Case-insensitive ASCIIbetical sort
				Collections.sort(files, new class() Comparator/*<File>*/ {

					public int compare(File f1, File f2) {
						return f1.getName().compareToIgnoreCase(f2.getName());
					}
				});
				break;
			case 2: // Sort by modified date, oldest first
				Collections.sort(files, new class() Comparator/*<File>*/ {

					public int compare(File f1, File f2) {
						return Long.valueOf(f1.lastModified()).compareTo(Long.valueOf(f2.lastModified()));
					}
				});
				break;
			case 1: // Sort by modified date, newest first
				Collections.sort(files, new class() Comparator/*<File>*/ {

					public int compare(File f1, File f2) {
						return Long.valueOf(f2.lastModified()).compareTo(Long.valueOf(f1.lastModified()));
					}
				});
				break;
			default: // Locale-sensitive A-Z
				Collections.sort(files, new class() Comparator/*<File>*/ {

					public int compare(File f1, File f2) {
						return collator.compare(f1.getName(), f2.getName());
					}
				});
				break;
		}

		foreach (File f ; files) {
			if (f.isDirectory()) {
				discoverable.add(f); // manageFile(f);
			}
		}

		foreach (File f ; files) {
			if (f.isFile()) {
				discoverable.add(f); // manageFile(f);
			}
		}
	}

	override
	public bool isRefreshNeeded() {
		long modified = 0;

		foreach (File f ; this.getConf().getFiles()) {
			if (f !is null) {
				modified = Math.max(modified, f.lastModified());
			}
		}

		return getLastRefreshTime() < modified;
	}

	override
	public void doRefreshChildren() {
		List/*<File>*/ files = getFileList();
		List/*<File>*/ addedFiles = new ArrayList/*<File>*/();
		List/*<DLNAResource>*/ removedFiles = new ArrayList/*<DLNAResource>*/();

		foreach (DLNAResource d ; getChildren()) {
			bool isNeedMatching = !(d.getClass() == MapFile._class || (cast(VirtualFolder)d !is null && !(cast(DVDISOFile)d !is null)));
			if (isNeedMatching && !foundInList(files, d)) {
				removedFiles.add(d);
			}
		}

		foreach (File f ; files) {
			if (!f.isHidden() && (f.isDirectory() || FormatFactory.getAssociatedExtension(f.getName()) !is null)) {
				addedFiles.add(f);
			}
		}

		foreach (DLNAResource f ; removedFiles) {
			LOGGER._debug("File automatically removed: " ~ f.getName());
		}

		foreach (File f ; addedFiles) {
			LOGGER._debug("File automatically added: " ~ f.getName());
		}

		// false: don't create the folder if it doesn't exist i.e. find the folder
		TranscodeVirtualFolder vf = getTranscodeFolder(false);

		foreach (DLNAResource f ; removedFiles) {
			getChildren().remove(f);

			if (vf !is null) {
				for (int j = vf.getChildren().size() - 1; j >= 0; j--) {
					if (vf.getChildren().get(j).getName().opEquals(f.getName())) {
						vf.getChildren().remove(j);
					}
				}
			}
		}

		foreach (File f ; addedFiles) {
			manageFile(f);
		}

		foreach (MapFileConfiguration f ; this.getConf().getChildren()) {
			addChild(new MapFile(f));
		}
	}

	private bool foundInList(List/*<File>*/ files, DLNAResource d) {
		foreach (File f; files) {
			if (!f.isHidden() && isNameMatch(f, d) && (isRealFolder(d) || isSameLastModified(f, d))) {
				files.remove(f);
				return true;
			}
		}
		return false;
	}

	private bool isSameLastModified(File f, DLNAResource d) {
		return d.getLastModified() == f.lastModified();
	}

	private bool isRealFolder(DLNAResource d) {
		return cast(RealFile)d !is null && d.isFolder();
	}

	private bool isNameMatch(File file, DLNAResource resource) {
		return (resource.getName().opEquals(file.getName()) || isDVDIsoMatch(file, resource));
	}

	private bool isDVDIsoMatch(File file, DLNAResource resource) {
		return (cast(DVDISOFile)resource !is null) &&
			resource.getName().startsWith(DVDISOFile.PREFIX) &&
			resource.getName().substring(DVDISOFile.PREFIX.length()).opEquals(file.getName());
	}

	override
	public String getSystemName() {
		return getName();
	}

	override
	public String getThumbnailContentType() {
		String thumbnailIcon = this.getConf().getThumbnailIcon();
		if (thumbnailIcon !is null && thumbnailIcon.toLowerCase().endsWith(".png")) {
			return HTTPResource.PNG_TYPEMIME;
		}
		return super.getThumbnailContentType();
	}

	override
	public InputStream getThumbnailInputStream() {
		return this.getConf().getThumbnailIcon() !is null
			? getResourceInputStream(this.getConf().getThumbnailIcon())
			: super.getThumbnailInputStream();
	}

	override
	public long length() {
		return 0;
	}

	override
	public String getName() {
		return this.getConf().getName();
	}

	override
	public bool isFolder() {
		return true;
	}

	override
	public InputStream getInputStream() {
		return null;
	}

	override
	public bool allowScan() {
		return isFolder();
	}

	/* (non-Javadoc)
	 * @see java.lang.Object#toString()
	 */
	override
	public String toString() {
		return "MapFile [name=" ~ getName() ~ ", id=" ~ getResourceId() ~ ", format=" ~ getFormat() ~ ", children=" ~ getChildren() ~ "]";
	}

	/**
	 * @return the conf
	 * @since 1.50.0
	 */
	protected MapFileConfiguration getConf() {
		return conf;
	}

	/**
	 * @param conf the conf to set
	 * @since 1.50.0
	 */
	protected void setConf(MapFileConfiguration conf) {
		this.conf = conf;
	}

	/**
	 * @return the potentialCover
	 * @since 1.50.0
	 */
	public File getPotentialCover() {
		return potentialCover;
	}

	/**
	 * @param potentialCover the potentialCover to set
	 * @since 1.50.0
	 */
	public void setPotentialCover(File potentialCover) {
		this.potentialCover = potentialCover;
	}
}
