module net.pms.util.SystemErrWrapper;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.OutputStream;

public class SystemErrWrapper : OutputStream {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!SystemErrWrapper();
	private int pos = 0;
	private byte line[] = new byte[5000];

	override
	public void write(int b) {
		if (b == 10) {
			byte text[] = new byte[pos];
			System.arraycopy(line, 0, text, 0, pos);
			logger.info(new String(text));
			pos = 0;
			line = new byte[5000];
		} else if (b != 13) {
			line[pos] = (byte) b;
			pos++;
		}
	}
}
