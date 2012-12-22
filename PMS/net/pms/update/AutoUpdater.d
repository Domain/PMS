module net.pms.update.AutoUpdater;

import net.pms.PMS;
import net.pms.util.UriRetriever;
import net.pms.util.UriRetrieverCallback;
import net.pms.util.Version;

import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.all;
import java.util.Observable;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

/**
 * Checks for and downloads new versions of PMS.
 * 
 * @author Tim Cox (mail@tcox.org)
 */
public class AutoUpdater : Observable , UriRetrieverCallback {
	private static const String TARGET_FILENAME = "new-version.exe";
	private static immutable Logger LOGGER = LoggerFactory.getLogger!AutoUpdater();

	public static enum State {
		NOTHING_KNOWN, POLLING_SERVER, NO_UPDATE_AVAILABLE, UPDATE_AVAILABLE, DOWNLOAD_IN_PROGRESS, DOWNLOAD_FINISHED, EXECUTING_SETUP, ERROR
	}

	private String serverUrl;
	private UriRetriever uriRetriever = new UriRetriever();
	private AutoUpdaterServerProperties serverProperties = new AutoUpdaterServerProperties();
	private Version currentVersion;
	private Executor executor = Executors.newSingleThreadExecutor();
	private State state = State.NOTHING_KNOWN;
	private Object stateLock = new Object();
	private Throwable errorStateCause;
	private int bytesDownloaded = -1;
	private int totalBytes = -1;
	private bool downloadCancelled = false;

	public this(String updateServerUrl, String currentVersion) {
		this.serverUrl = updateServerUrl; // may be null if updating is disabled
		this.currentVersion = new Version(currentVersion);
	}

	public void pollServer() {
		if (serverUrl !is null) { // don't poll if the server URL is null
			executor.execute(new class() Runnable {
				public void run() {
					try {
						doPollServer();
					} catch (UpdateException e) {
						setErrorState(e);
					}
				}
			});
		}
	}

	private void doPollServer() {
		assertNotInErrorState();

		try {
			setState(State.POLLING_SERVER);
			byte[] propertiesAsData = uriRetriever.get(serverUrl);
			synchronized (stateLock) {
				serverProperties.loadFrom(propertiesAsData);
				setState(isUpdateAvailable() ? State.UPDATE_AVAILABLE : State.NO_UPDATE_AVAILABLE);
			}
		} catch (IOException e) {
			wrapException(serverUrl, "Cannot download properties", e);
		}
	}

	public void getUpdateFromNetwork() {
		executor.execute(new class() Runnable {
			public void run() {
				try {
					doGetUpdateFromNetwork();
				} catch (UpdateException e) {
					setErrorState(e);
				}
			}
		});
	}

	public void runUpdateAndExit() {
		executor.execute(new class() Runnable {
			public void run() {
				try {
					doRunUpdateAndExit();
				} catch (UpdateException e) {
					setErrorState(e);
				}
			}
		});
	}

	private void setErrorState(UpdateException e) {
		synchronized (stateLock) {
			setState(State.ERROR);
			errorStateCause = e;
		}
	}

	private void doGetUpdateFromNetwork() {
		assertNotInErrorState();
		assertUpdateIsAvailable();

		setState(State.DOWNLOAD_IN_PROGRESS);
		downloadUpdate();
		setState(State.DOWNLOAD_FINISHED);
	}

	private void doRunUpdateAndExit() {
		synchronized (stateLock) {
			if (state != State.DOWNLOAD_FINISHED) {
				throw new UpdateException("Must download before run");
			}
		}

		setState(State.EXECUTING_SETUP);
		launchExe();
		System.exit(0);
	}

	private void launchExe() {
		try {
			File exe = new File(TARGET_FILENAME);
			if (!exe.exists()) {
				exe = new File(PMS.getConfiguration().getTempFolder(), TARGET_FILENAME);
			}
			Runtime.getRuntime().exec(exe.getAbsolutePath());
		} catch (IOException e) {
			wrapException(serverProperties.getDownloadUrl(), "Unable to run update. You may need to manually download it.", e);
		}
	}

	private void assertUpdateIsAvailable() {
		synchronized (stateLock) {
			if (!serverProperties.isStateValid()) {
				throw new UpdateException("Server error. Try again later.");
			}

			if (!isUpdateAvailable()) {
				throw new UpdateException("Attempt to perform non-existent update");
			}
		}
	}

	private void assertNotInErrorState() {
		synchronized (stateLock) {
			if (state == State.ERROR) {
				throw new UpdateException("Update system must be reset after an error.");
			}
		}
	}

	private synchronized void setState(State value) {
		synchronized (stateLock) {
			state = value;

			if (state == State.DOWNLOAD_FINISHED) {
				bytesDownloaded = totalBytes;
			} else if (state != State.DOWNLOAD_IN_PROGRESS) {
				bytesDownloaded = -1;
				totalBytes = -1;
			}

			if (state != State.ERROR) {
				errorStateCause = null;
			}
		}

		setChanged();
		notifyObservers();
	}

	public bool isUpdateAvailable() {
		// TODO (tcox): Make updates work on Linux and Mac
		return Version.isPmsUpdatable(currentVersion, serverProperties.getLatestVersion());
	}

	private void downloadUpdate() {
		String downloadUrl = serverProperties.getDownloadUrl();

		try {
			byte[] download = uriRetriever.getWithCallback(downloadUrl, this);
			writeToDisk(download);
		} catch (IOException e) {
			wrapException(downloadUrl, "Cannot download update", e);
		}
	}

	private void writeToDisk(byte[] download) {
		File target = new File(TARGET_FILENAME);
		InputStream downloadedFromNetwork = new ByteArrayInputStream(download);
		FileOutputStream fileOnDisk = null;

		try {
			try {
				fileOnDisk = new FileOutputStream(target);
				fileOnDisk.write("test".getBytes());
			} catch (Exception e) {
				// seems no rights
				target = new File(PMS.getConfiguration().getTempFolder(), TARGET_FILENAME);
			} finally {
				fileOnDisk.close();
			}
			fileOnDisk = new FileOutputStream(target);
			int bytesSaved = IOUtils.copy(downloadedFromNetwork, fileOnDisk);
			logger.info("Wrote " ~ bytesSaved.toString() ~ " bytes to " ~ target.getAbsolutePath());
		} finally {
			IOUtils.closeQuietly(downloadedFromNetwork);
			IOUtils.closeQuietly(fileOnDisk);
		}
	}

	private void wrapException(String downloadUrl, String message, Throwable cause) {
		throw new UpdateException("Error: " ~ message, cause);
	}

	override
	public void progressMade(String uri, int bytesDownloaded, int totalBytes) {
		synchronized (stateLock) {
			this.bytesDownloaded = bytesDownloaded;
			this.totalBytes = totalBytes;

			if (downloadCancelled) {
				setErrorState(new UpdateException("Download cancelled"));
				throw new CancelDownloadException();
			}
		}

		setChanged();
		notifyObservers();
	}

	public State getState() {
		synchronized (stateLock) {
			return state;
		}
	}

	public Throwable getErrorStateCause() {
		synchronized (stateLock) {
			return errorStateCause;
		}
	}

	public int getBytesDownloaded() {
		synchronized (stateLock) {
			return bytesDownloaded;
		}
	}

	public int getTotalBytes() {
		synchronized (stateLock) {
			return totalBytes;
		}
	}

	public void cancelDownload() {
		synchronized (stateLock) {
			downloadCancelled = true;
		}
	}

	public bool isDownloadCancelled() {
		synchronized (stateLock) {
			return downloadCancelled;
		}
	}
}
