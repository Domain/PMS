module net.pms.io.InternalJavaProcessImpl;

//import java.lang.exceptions;
import java.lang.exceptions;
import java.io.InputStream;
import java.util.List;

public class InternalJavaProcessImpl : ProcessWrapper {
	private InputStream input;

	public this(InputStream input) {
		this.input = input;
	}

	override
	public InputStream getInputStream(long seek) {
		return input;
	}

	override
	public List/*<String>*/ getResults() {
		return null;
	}

	override
	public bool isDestroyed() {
		return true;
	}

	override
	public void runInNewThread() {
	}

	override
	public bool isReadyToStop() {
		return false;
	}

	override
	public void setReadyToStop(bool nullable) {
	}

	override
	public void stopProcess() {
	}
}
