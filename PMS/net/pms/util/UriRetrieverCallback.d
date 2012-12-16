module net.pms.util.UriRetrieverCallback;

public interface UriRetrieverCallback {
	void progressMade(String uri, int bytesDownloaded, int totalBytes) throws CancelDownloadException;

	public class CancelDownloadException : Exception {
		private static final long serialVersionUID = 1L;
	}
}
