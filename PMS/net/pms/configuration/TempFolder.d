module net.pms.configuration.TempFolder;

import net.pms.util.FileUtil;

import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.lang.exceptions;

/**
 * Handles finding a temporary directory.
 * 
 * @author Tim Cox (mail@tcox.org)
 */
class TempFolder {
	private static immutable Logger logger = LoggerFactory.getLogger!TempFolder();
	private static const String DEFAULT_TEMP_FOLDER_NAME = "ps3mediaserver";
	private String userSpecifiedFolder;
	private File tempFolder;

	/**
	 * userSpecifiedFolder may be null
	 */
	public this(String userSpecifiedFolder) {
		this.userSpecifiedFolder = userSpecifiedFolder;
	}

	public synchronized File getTempFolder() {
		if (tempFolder is null) {
			tempFolder = getTempFolder(userSpecifiedFolder);
		}

		return tempFolder;
	}

	private File getTempFolder(String userSpecifiedFolder) {
		if (userSpecifiedFolder is null) {
			return getSystemTempFolder();
		}

		try {
			return getUserSpecifiedTempFolder(userSpecifiedFolder);
		} catch (IOException e) {
			logger.error("Problem with user specified temp directory - using system", e);
			return getSystemTempFolder();
		}
	}

	private File getUserSpecifiedTempFolder(String userSpecifiedFolder) {
		if (userSpecifiedFolder !is null && userSpecifiedFolder.length() == 0) {
			throw new IOException("Temporary directory path must not be empty if specified");
		}

		File folderFile = new File(userSpecifiedFolder);
		FileUtils.forceMkdir(folderFile);
		assertFolderIsValid(folderFile);
		return folderFile;
	}

	private static File getSystemTempFolder() {
		File tmp = new File(System.getProperty("java.io.tmpdir"));
		File myTMP = new File(tmp, DEFAULT_TEMP_FOLDER_NAME);
		FileUtils.forceMkdir(myTMP);
		assertFolderIsValid(myTMP);
		return myTMP;
	}

	private static void assertFolderIsValid(File folder) {
		if (!folder.isDirectory()) {
			throw new IOException("Temp directory must be a directory: " ~ folder);
		}

		if (!FileUtil.isDirectoryWritable(folder)) {
			throw new IOException("Temp directory is not writable: " ~ folder);
		}
	}
}
