module net.pms.xmlwise.XmlParseException;

/**
 * @deprecated This package is a copy of a third-party library (xmlwise). Future releases will use the original library.
 *
 * Generic exception when parsing xml.
 * 
 * @author Christoffer Lerno
 */
deprecated
public class XmlParseException : Exception {
	private static final long serialVersionUID = -3246260520113823143L;

	public XmlParseException(Throwable cause) {
		super(cause);
	}

	public XmlParseException(String message) {
		super(message);
	}

	public XmlParseException(String message, Throwable cause) {
		super(message, cause);
	}
}
