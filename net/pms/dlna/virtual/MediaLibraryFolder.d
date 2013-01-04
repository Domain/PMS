module net.pms.dlna.virtual.MediaLibraryFolder;

import net.pms.PMS;
import net.pms.dlna.all;

import java.io.File;
import java.util.ArrayList;

public class MediaLibraryFolder : VirtualFolder {
	public static const int FILES = 0;
	public static const int TEXTS = 1;
	public static const int PLAYLISTS = 2;
	public static const int ISOS = 3;
	private String[] sqls;
	private int[] expectedOutputs;
	private DLNAMediaDatabase database;

	public this(String name, String sql, int expectedOutput) {
		this(name, [sql], [expectedOutput]);
	}

	public this(String name, String sql[], int expectedOutput[]) {
		super(name, null);
		this.sqls = sql;
		this.expectedOutputs = expectedOutput;
		this.database = PMS.get().getDatabase();
		// double check the database has been initialized (via PMS.init -> PMS.initializeDatabase)
		// http://www.ps3mediaserver.org/forum/viewtopic.php?f=6&t=11474
		assert(this.database !is null);
	}

	override
	public void discoverChildren() {
		if (sqls.length > 0) {
			String sql = sqls[0];
			int expectedOutput = expectedOutputs[0];
			if (sql !is null) {
				sql = transformSQL(sql);
				if (expectedOutput == FILES) {
					ArrayList/*<File>*/ list = database.getFiles(sql);
					if (list !is null) {
						foreach (File f ; list) {
							addChild(new RealFile(f));
						}
					}
				} else if (expectedOutput == PLAYLISTS) {
					ArrayList/*<File>*/ list = database.getFiles(sql);
					if (list !is null) {
						foreach (File f ; list) {
							addChild(new PlaylistFolder(f));
						}
					}
				} else if (expectedOutput == ISOS) {
					ArrayList/*<File>*/ list = database.getFiles(sql);
					if (list !is null) {
						foreach (File f ; list) {
							addChild(new DVDISOFile(f));
						}
					}
				} else if (expectedOutput == TEXTS) {
					ArrayList/*<String>*/ list = database.getStrings(sql);
					if (list !is null) {
						foreach (String s ; list) {
							String[] sqls2 = new String[sqls.length - 1];
							int[] expectedOutputs2 = new int[expectedOutputs.length - 1];
							System.arraycopy(sqls, 1, sqls2, 0, sqls2.length);
							System.arraycopy(expectedOutputs, 1, expectedOutputs2, 0, expectedOutputs2.length);
							addChild(new MediaLibraryFolder(s, sqls2, expectedOutputs2));
						}
					}
				}
			}
		}
	}

	override
	public void resolve() {
		super.resolve();
	}

	private String transformSQL(String sql) {

		sql = sql.replace("${0}", transformName(getName()));
		if (getParent() !is null) {
			sql = sql.replace("${1}", transformName(getParent().getName()));
			if (getParent().getParent() !is null) {
				sql = sql.replace("${2}", transformName(getParent().getParent().getName()));
				if (getParent().getParent().getParent() !is null) {
					sql = sql.replace("${3}", transformName(getParent().getParent().getParent().getName()));
					if (getParent().getParent().getParent().getParent() !is null) {
						sql = sql.replace("${4}", transformName(getParent().getParent().getParent().getParent().getName()));
					}
				}
			}
		}
		return sql;
	}

	private String transformName(String name) {
		if (name.opEquals(DLNAMediaDatabase.NONAME)) {
			name = "";
		}
		name = name.replace("'", "''"); // issue 448
		return name;
	}

	override
	public bool isRefreshNeeded() {
		return true;
	}

	override
	public void doRefreshChildren() {
		ArrayList/*<File>*/ list = null;
		ArrayList/*<String>*/ strings = null;
		int expectedOutput = 0;
		if (sqls.length > 0) {
			String sql = sqls[0];
			expectedOutput = expectedOutputs[0];
			if (sql !is null) {
				sql = transformSQL(sql);
				if (expectedOutput == FILES || expectedOutput == PLAYLISTS || expectedOutput == ISOS) {
					list = database.getFiles(sql);
				} else if (expectedOutput == TEXTS) {
					strings = database.getStrings(sql);
				}
			}
		}
		ArrayList/*<File>*/ addedFiles = new ArrayList/*<File>*/();
		ArrayList/*<String>*/ addedString = new ArrayList/*<String>*/();
		ArrayList/*<DLNAResource>*/ removedFiles = new ArrayList/*<DLNAResource>*/();
		ArrayList/*<DLNAResource>*/ removedString = new ArrayList/*<DLNAResource>*/();
		int i = 0;
		if (list !is null) {
			foreach (File f ; list) {
				bool present = false;
				foreach (DLNAResource d ; getChildren()) {
					if (i == 0 && (!(cast(VirtualFolder)d !is null) || (cast(MediaLibraryFolder)d !is null))) {
						removedFiles.add(d);
					}
					String name = d.getName();
					long lm = d.getLastModified();
					bool video_ts_hack = (cast(DVDISOFile)d !is null) && d.getName().startsWith(DVDISOFile.PREFIX) && d.getName().substring(DVDISOFile.PREFIX.length()).opEquals(f.getName());
					if ((f.getName().opEquals(name) || video_ts_hack) && f.lastModified() == lm) {
						removedFiles.remove(d);
						present = true;
					}
				}
				i++;
				if (!present) {
					addedFiles.add(f);
				}
			}
		}
		i = 0;
		if (strings !is null) {
			foreach (String f ; strings) {
				bool present = false;
				foreach (DLNAResource d ; getChildren()) {
					if (i == 0 && (!(cast(VirtualFolder)d !is null) || (cast(MediaLibraryFolder)d !is null))) {
						removedString.add(d);
					}
					String name = d.getName();
					if (f.opEquals(name)) {
						removedString.remove(d);
						present = true;
					}
				}
				i++;
				if (!present) {
					addedString.add(f);
				}
			}
		}

		foreach (DLNAResource f ; removedFiles) {
			getChildren().remove(f);
		}
		foreach (DLNAResource s ; removedString) {
			getChildren().remove(s);
		}
		foreach (File f ; addedFiles) {
			if (expectedOutput == FILES) {
				addChild(new RealFile(f));
			} else if (expectedOutput == PLAYLISTS) {
				addChild(new PlaylistFolder(f));
			} else if (expectedOutput == ISOS) {
				addChild(new DVDISOFile(f));
			}
		}
		foreach (String f ; addedString) {
			if (expectedOutput == TEXTS) {
				String[] sqls2 = new String[sqls.length - 1];
				int[] expectedOutputs2 = new int[expectedOutputs.length - 1];
				System.arraycopy(sqls, 1, sqls2, 0, sqls2.length);
				System.arraycopy(expectedOutputs, 1, expectedOutputs2, 0, expectedOutputs2.length);
				addChild(new MediaLibraryFolder(f, sqls2, expectedOutputs2));
			}
		}

		//return removedFiles.size() != 0 || addedFiles.size() != 0 || removedString.size() != 0 || addedString.size() != 0;
	}
}
