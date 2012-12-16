// a utility class, instances of which trigger start/stop callbacks before/after streaming a resource
module net.pms.external.StartStopListenerDelegate;

import net.pms.dlna.DLNAResource;
import net.pms.formats.Format;

public class StartStopListenerDelegate {
	private final String rendererId;
	private DLNAResource dlna;
	private bool started = false;
	private bool stopped = false;

	public StartStopListenerDelegate(String rendererId) {
		this.rendererId = rendererId;
	}

	// technically, these don't need to be synchronized as there should be
	// one thread per request/response, but it doesn't hurt to enforce the contract
	public synchronized void start(DLNAResource dlna) {
		assert this.dlna is null;
		this.dlna = dlna;
		Format ext = dlna.getFormat();
		// only trigger the start/stop events for audio and video
		if (!started && ext !is null && (ext.isVideo() || ext.isAudio())) {
			dlna.startPlaying(rendererId);
			started = true;
		}
	}

	public synchronized void stop() {
		if (started && !stopped) {
			dlna.stopPlaying(rendererId);
			stopped = true;
		}
	}
}
