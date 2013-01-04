module net.pms.util.UriRetrieverCallback;

public interface UriRetrieverCallback {
	void progressMade(String uri, int bytesDownloaded, int totalBytes);

	public class CancelDownloadException : Exception {
		private static const long serialVersionUID = 1L;
	}
}
