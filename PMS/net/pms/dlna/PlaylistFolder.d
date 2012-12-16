module net.pms.dlna.PlaylistFolder;

import net.pms.PMS;
import net.pms.formats.Format;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.util.ArrayList;

public class PlaylistFolder : DLNAResource {
	private static final Logger logger = LoggerFactory.getLogger(PlaylistFolder.class);
	private File playlistfile;
	private bool valid = true;

	public File getPlaylistfile() {
		return playlistfile;
	}

	public PlaylistFolder(File f) {
		playlistfile = f;
		setLastModified(playlistfile.lastModified());
	}

	override
	public InputStream getInputStream() throws IOException {
		return null;
	}

	override
	public String getName() {
		return playlistfile.getName();
	}

	override
	public String getSystemName() {
		return playlistfile.getName();
	}

	override
	public bool isFolder() {
		return true;
	}

	override
	public bool isValid() {
		return valid;
	}

	override
	public long length() {
		return 0;
	}

	override
	public synchronized void resolve() {
		if (playlistfile.length() < 10000000) {
			ArrayList<Entry> entries = new ArrayList<Entry>();
			bool m3u = false;
			bool pls = false;
			try {
				BufferedReader br = new BufferedReader(new FileReader(playlistfile));
				String line;
				while (!m3u && !pls && (line = br.readLine()) !is null) {
					line = line.trim();
					if (line.startsWith("#EXTM3U")) {
						m3u = true;
						logger.debug("Reading m3u playlist: " + playlistfile.getName());
					} else if (line.length() > 0 && line.equals("[playlist]")) {
						pls = true;
						logger.debug("Reading PLS playlist: " + playlistfile.getName());
					}
				}
				String fileName = null;
				String title = null;
				while ((line = br.readLine()) !is null) {
					line = line.trim();
					if (pls) {
						if (line.length() > 0 && !line.startsWith("#")) {
							int eq = line.indexOf("=");
							if (eq != -1) {
								String value = line.substring(eq + 1);
								String var = line.substring(0, eq).toLowerCase();
								fileName = null;
								title = null;
								int index = 0;
								if (var.startsWith("file")) {
									index = Integer.valueOf(var.substring(4));
									fileName = value;
								} else if (var.startsWith("title")) {
									index = Integer.valueOf(var.substring(5));
									title = value;
								}
								if (index > 0) {
									while (entries.size() < index) {
										entries.add(null);
									}
									Entry entry = entries.get(index - 1);
									if (entry is null) {
										entry = new Entry();
										entries.set(index - 1, entry);
									}
									if (fileName !is null) {
										entry.fileName = fileName;
									}
									if (title !is null) {
										entry.title = title;
									}
								}
							}
						}
					} else if (m3u) {
						if (line.startsWith("#EXTINF:")) {
							line = line.substring(8).trim();
							if (line.matches("^-?\\d+,.+")) {
								title = line.substring(line.indexOf(",") + 1).trim();
							} else {
								title = line;
							}
						} else if (!line.startsWith("#") && !line.matches("^\\s*$")) {
							// Non-comment and non-empty line contains the filename
							fileName = line;
							Entry entry = new Entry();
							entry.fileName = fileName;
							entry.title = title;
							entries.add(entry);
							title = null;
						}
					}
				}
				br.close();
			} catch (NumberFormatException e) {
				logger.error(null, e);
			} catch (IOException e) {
				logger.error(null, e);
			}
			for (Entry entry : entries) {
				if (entry is null) {
					continue;
				}
				String fileName = entry.fileName;
				logger.debug("Adding " + (pls ? "PLS " : (m3u ? "M3U " : "")) + "entry: " + entry);
				if (!fileName.toLowerCase().startsWith("http://") && !fileName.toLowerCase().startsWith("mms://")) {
					File en1 = new File(playlistfile.getParentFile(), fileName);
					File en2 = new File(fileName);
					if (en1.exists()) {
						addChild(new RealFile(en1, entry.title));
						valid = true;
					} else {
						if (en2.exists()) {
							addChild(new RealFile(en2, entry.title));
							valid = true;
						}
					}
				}
			}
			PMS.get().storeFileInCache(playlistfile, Format.PLAYLIST);
			for (DLNAResource r : getChildren()) {
				r.resolve();
			}
		}
	}

	private static class Entry {
		public String fileName;
		public String title;

		override
		public String toString() {
			return "[" + fileName + "," + title + "]";
		}
	}
}
