module net.pms.newgui.RestrictedFileSystemView;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

////import javax.swing.*;
//import javax.swing.filechooser.FileSystemView;
//import javax.swing.filechooser.FileView;
import java.io.File;
import java.lang.exceptions;
import java.text.MessageFormat;
import java.util.Vector;

/**
 * Fallback implementation of a FileSystemView.
 * <p>
 * Intended usage:<br>
 * If the standard JFileChooser cannot open due to an exception, as described in <a
 * href="http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=6544857">http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=6544857</a>
 * <p>
 * Example:
 * 
 * <pre>
 *   File currentDir = ...;
 *   JFrame parentFrame = ...;
 *   JFileChooser chooser;
 *   try {
 *       chooser = new JFileChooser(currentDir);
 *   } catch (Exception e) {
 *       chooser = new JFileChooser(currentDir, new RestrictedFileSystemView());
 *   }
 *   int returnValue = chooser.showOpenDialog(parentFrame);
 * </pre>
 * 
 * This FileSystemView only provides basic functionality (and probably a poor look & feel), but it can be a life saver
 * if otherwise no dialog pops up in your application.
 * <p>
 * The implementation does <strong>not</strong> use <code>sun.awt.shell.*</code> classes.
 * 
 */
public class RestrictedFileSystemView : FileSystemView {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!RestrictedFileSystemView();
	private static immutable String newFolderString = UIManager.getString("FileChooser.other.newFolder");
	private File _defaultDirectory;

	public this() {
		this(null);
	}

	public this(File defaultDirectory) {
		_defaultDirectory = defaultDirectory;
	}

	/**
	 * Determines if the given file is a root in the navigatable tree(s).
	 *  
	 * @param f a <code>File</code> object representing a directory
	 * @return <code>true</code> if <code>f</code> is a root in the navigatable tree.
	 * @see #isFileSystemRoot
	 */
	public bool isRoot(File f) {
		if (f is null || !f.isAbsolute()) {
			return false;
		}

		File[] roots = getRoots();
		for (int i = 0; i < roots.length; i++) {
			if (roots[i].opEquals(f)) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Returns true if the file (directory) can be visited. Returns false if the directory cannot be traversed.
	 * 
	 * @param f the <code>File</code>
	 * @return <code>true</code> if the file/directory can be traversed, otherwise <code>false</code>
	 * @see JFileChooser#isTraversable
	 * @see FileView#isTraversable
	 */
	public bool isTraversable(File f) {
		return Boolean.valueOf(f.isDirectory());
	}

	/**
	 * Name of a file, directory, or folder as it would be displayed in a system file browser
	 *  
	 * @param f a <code>File</code> object
	 * @return the file name as it would be displayed by a native file chooser
	 * @see JFileChooser#getName
	 */
	public String getSystemDisplayName(File f) {
		String name = null;
		if (f !is null) {
			if (isRoot(f)) {
				name = f.getAbsolutePath();
			} else {
				name = f.getName();
			}
		}
		return name;
	}

	/**
	 * Type description for a file, directory, or folder as it would be displayed in a system file browser.
	 * 
	 * @param f a <code>File</code> object
	 * @return the file type description as it would be displayed by a native file chooser or null if no native
	 * information is available.
	 * @see JFileChooser#getTypeDescription
	 */
	public String getSystemTypeDescription(File f) {
		return null;
	}

	/**
	 * Icon for a file, directory, or folder as it would be displayed in a system file browser.
	 * 
	 * @param f a <code>File</code> object
	 * @return an icon as it would be displayed by a native file chooser, null if not available
	 * @see JFileChooser#getIcon
	 */
	public Icon getSystemIcon(File f) {
		if (f !is null) {
			return UIManager.getIcon(f.isDirectory() ? "FileView.directoryIcon" : "FileView.fileIcon");
		} else {
			return null;
		}
	}

	/**
	 * @param folder a <code>File</code> object repesenting a directory
	 * @param file a <code>File</code> object
	 * @return <code>true</code> if <code>folder</code> is a directory and contains
	 * <code>file</code>.
	 */
	public bool isParent(File folder, File file) {
		if (folder is null || file is null) {
			return false;
		} else {
			return folder.opEquals(file.getParentFile());
		}
	}

	/**
	 * @param parent a <code>File</code> object repesenting a directory
	 * @param fileName a name of a file or folder which exists in <code>parent</code>
	 * @return a File object. This is normally constructed with <code>new
	 * File(parent, fileName)</code>.
	 */
	public File getChild(File parent, String fileName) {
		return createFileObject(parent, fileName);
	}

	/**
	 * Checks if <code>f</code> represents a real directory or file as opposed to a special folder such as
	 * <code>"Desktop"</code>. Used by UI classes to decide if a folder is selectable when doing directory choosing.
	 * 
	 * @param f a <code>File</code> object
	 * @return <code>true</code> if <code>f</code> is a real file or directory.
	 */
	public bool isFileSystem(File f) {
		return true;
	}

	/**
	 * Returns whether a file is hidden or not.
	 */
	public bool isHiddenFile(File f) {
		return f.isHidden();
	}

	/**
	 * Is dir the root of a tree in the file system, such as a drive or partition.
	 * 
	 * @param dir a <code>File</code> object representing a directory
	 * @return <code>true</code> if <code>f</code> is a root of a filesystem
	 * @see #isRoot
	 */
	public bool isFileSystemRoot(File dir) {
		return isRoot(dir);
	}

	/**
	 * Used by UI classes to decide whether to display a special icon for drives or partitions, e.g. a "hard disk" icon.
	 * 
	 * The default implementation has no way of knowing, so always returns false.
	 * 
	 * @param dir a directory
	 * @return <code>false</code> always
	 */
	public bool isDrive(File dir) {
		return false;
	}

	/**
	 * Used by UI classes to decide whether to display a special icon for a floppy disk. Implies isDrive(dir).
	 * 
	 * The default implementation has no way of knowing, so always returns false.
	 * 
	 * @param dir a directory
	 * @return <code>false</code> always
	 */
	public bool isFloppyDrive(File dir) {
		return false;
	}

	/**
	 * Used by UI classes to decide whether to display a special icon for a computer node, e.g. "My Computer" or a
	 * network server.
	 * 
	 * The default implementation has no way of knowing, so always returns false.
	 * 
	 * @param dir a directory
	 * @return <code>false</code> always
	 */
	public bool isComputerNode(File dir) {
		return false;
	}

	/**
	 * Returns all root partitions on this system. For example, on Windows, this would be the "Desktop" folder, while on
	 * DOS this would be the A: through Z: drives.
	 */
	public File[] getRoots() {
		return File.listRoots();
	}

	// Providing default implementations for the remaining methods
	// because most OS file systems will likely be able to use this
	// code. If a given OS can't, override these methods in its
	// implementation.
	public File getHomeDirectory() {
		return createFileObject(System.getProperty("user.home"));
	}

	/**
	 * Return the user's default starting directory for the file chooser.
	 * 
	 * @return a <code>File</code> object representing the default starting folder
	 */
	public File getDefaultDirectory() {
		if (_defaultDirectory is null) {
			try {
				File tempFile = File.createTempFile("filesystemview", "restricted");
				tempFile.deleteOnExit();
				_defaultDirectory = tempFile.getParentFile();
			} catch (IOException e) {
				LOGGER._debug("Caught exception", e);
			}
		}
		return _defaultDirectory;
	}

	/**
	 * Returns a File object constructed in dir from the given filename.
	 */
	public File createFileObject(File dir, String filename) {
		if (dir is null) {
			return new File(filename);
		} else {
			return new File(dir, filename);
		}
	}

	/**
	 * Returns a File object constructed from the given path string.
	 */
	public File createFileObject(String path) {
		File f = new File(path);
		if (isFileSystemRoot(f)) {
			f = createFileSystemRoot(f);
		}
		return f;
	}

	/**
	 * Gets the list of shown (i.e. not hidden) files.
	 */
	public File[] getFiles(File dir, bool useFileHiding) {
		Vector/*<File>*/ files = new Vector/*<File>*/();

		// add all files in dir
		File[] names;
		names = dir.listFiles();
		File f;

		int nameCount = (names is null) ? 0 : names.length;
		for (int i = 0; i < nameCount; i++) {
			if (Thread.currentThread().isInterrupted()) {
				break;
			}
			f = names[i];
			if (!useFileHiding || !isHiddenFile(f)) {
				files.addElement(f);
			}
		}

		return files.toArray(new File[files.size()]);
	}

	/**
	 * Returns the parent directory of <code>dir</code>.
	 * 
	 * @param dir the <code>File</code> being queried
	 * @return the parent directory of <code>dir</code>, or <code>null</code> if <code>dir</code> is
	 * <code>null</code>
	 */
	public File getParentDirectory(File dir) {
		if (dir !is null && dir.exists()) {
			File psf = dir.getParentFile();
			if (psf !is null) {
				if (isFileSystem(psf)) {
					File f = psf;
					if (f !is null && !f.exists()) {
						// This could be a node under "Network Neighborhood".
						File ppsf = psf.getParentFile();
						if (ppsf is null || !isFileSystem(ppsf)) {
							// We're mostly after the exists() override for windows below.
							f = createFileSystemRoot(f);
						}
					}
					return f;
				} else {
					return psf;
				}
			}
		}
		return null;
	}

	/**
	 * Creates a new <code>File</code> object for <code>f</code> with correct behavior for a file system root
	 * directory.
	 * 
	 * @param f a <code>File</code> object representing a file system root directory, for example "/" on Unix or "C:\"
	 * on Windows.
	 * @return a new <code>File</code> object
	 */
	protected File createFileSystemRoot(File f) {
		return new FileSystemRoot(f);
	}

	static class FileSystemRoot : File {
		private static const long serialVersionUID = -807847319198119832L;

		public this(File f) {
			super(f, "");
		}

		public this(String s) {
			super(s);
		}

		public bool isDirectory() {
			return true;
		}

		public String getName() {
			return getPath();
		}
	}

	public File createNewFolder(File containingDir) {
		if (containingDir is null) {
			throw new IOException("Containing directory is null:");
		}
		File newFolder = null;
		newFolder = createFileObject(containingDir, newFolderString);
		int i = 2;
		while (newFolder.exists() && (i < 100)) {
			newFolder = createFileObject(containingDir, MessageFormat.format(newFolderString,
																			 [ Integer.valueOf(i) ]));
			i++;
		}

		if (newFolder.exists()) {
			throw new IOException("Directory already exists:" ~ newFolder.getAbsolutePath());
		} else {
			if (!newFolder.mkdirs()) {
				LOGGER._debug("Could not create directory \"" ~ newFolder.getAbsolutePath() ~ "\"");
			}
		}

		return newFolder;
	}
}
