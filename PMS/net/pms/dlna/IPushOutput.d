module net.pms.dlna.IPushOutput;

import java.io.IOException;
import java.io.OutputStream;

public interface IPushOutput {
	public void push(OutputStream _out);
	public bool isUnderlyingSeekSupported();
}
