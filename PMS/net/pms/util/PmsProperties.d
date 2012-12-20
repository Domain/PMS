module net.pms.util.PmsProperties;

import java.io.IOException;
import java.io.InputStream;
import java.io.StringReader;
import java.io.UnsupportedEncodingException;
import java.util.Properties;

/**
 * Convenience wrapper around the Java Properties class.
 * 
 * @author Tim Cox (mail@tcox.org)
 */
public class PmsProperties {
	private immutable Properties properties = new Properties();
	private static const String ENCODING = "UTF-8";

	public void loadFromByteArray(byte[] data) {
		try {
			String utf = new String(data, ENCODING);
			StringReader reader = new StringReader(utf);
			properties.clear();
			properties.load(reader);
			reader.close();
		} catch (UnsupportedEncodingException e) {
			throw new IOException("Could not decode " ~ ENCODING);
		}
	}

	/**
	 * Initialize from a properties file.
	 * @param filename The properties file.
	 * @throws IOException
	 */
	public void loadFromResourceFile(String filename) {
		InputStream inputStream = getClass().getResourceAsStream(filename);

		try {
			properties.load(inputStream);
		} finally {
			inputStream.close();
		}
	}

	public void clear() {
		properties.clear();
	}

	public String get(String key) {
		Object obj = properties.get(key);
		if (obj !is null) {
			return trimAndRemoveQuotes(obj.toString());
		} else {
			return "";
		}
	}

	private static String trimAndRemoveQuotes(String _in) {
		_in = _in.trim();
		if (_in.startsWith("\"")) {
			_in = _in.substring(1);
		}
		if (_in.endsWith("\"")) {
			_in = _in.substring(0, _in.length() - 1);
		}
		return _in;
	}

	public bool containsKey(String key) {
		return properties.containsKey(key);
	}
}
