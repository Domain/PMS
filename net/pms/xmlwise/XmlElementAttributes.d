module net.pms.xmlwise.XmlElementAttributes;

import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;

import java.util.HashMap;
import java.util.Map;

/**
 * @deprecated This package is a copy of a third-party library (xmlwise). Future releases will use the original library.
 *
 * This is a hash map containing all attributes of a single
 * element.
 * <p>
 * Aside from the hash map methods, it also has convenience
 * methods for extracting integers, bools and doubles.
 *
 * @author Christoffer Lerno
 */
deprecated
public class XmlElementAttributes : HashMap/*<String, String>*/ {
	/**
	 * Creates an empty element attribute map.
	 */
	this() {
	}

	/**
	 * Creates an object given an Element object.
	 *
	 * @param element the element to read from.
	 */
	public this(Element element) {
		super(element.getAttributes().getLength());
		NamedNodeMap map = element.getAttributes();
		int attributesLength = map.getLength();
		for (int i = 0; i < attributesLength; i++) {
			put(map.item(i).getNodeName(), map.item(i).getNodeValue());
		}
	}

	/**
	 * Get an integer attribute.
	 *
	 * @param attribute the name of the attribute.
	 * @return the integer value of the attribute.
	 * @throws XmlParseException if we fail to parse this attribute as an int, or the attribute is missing.
	 */
	public int getInt(String attribute) {
		String value = get(attribute);
		if (value is null) {
			throw new XmlParseException("Could not find attribute " ~ attribute);
		}
		try {
			return Integer.parseInt(value);
		} catch (NumberFormatException e) {
			throw new XmlParseException("Failed to parse int attribute " ~ attribute, e);
		}
	}

	/**
	 * Get a double attribute.
	 *
	 * @param attribute the name of the attribute.
	 * @return the double value of the attribute.
	 * @throws XmlParseException if we fail to parse this attribute as an double, or the attribute is missing.
	 */
	public double getDouble(String attribute) {
		String value = get(attribute);
		if (value is null) {
			throw new XmlParseException("Could not find attribute " ~ attribute);
		}
		try {
			return Double.parseDouble(value);
		} catch (NumberFormatException e) {
			throw new XmlParseException("Failed to parse double attribute " ~ attribute, e);
		}
	}

	/**
	 * Get an bool attribute.
	 * <p>
	 * "true", "yes" and "y" are all interpreted as true. (Case-independent)
	 * <p>
	 * "false", "no" and "no" are all interpreted at false. (Case-independent)
	 *
	 * @param attribute the name of the attribute.
	 * @return the bool value of the attribute.
	 * @throws XmlParseException if the attribute value does match true or false as defined, or the attribute is missing.
	 */
	public bool getBoolean(String attribute) {
		String value = get(attribute);
		if (value is null) {
			throw new XmlParseException("Could not find attribute " ~ attribute);
		}
		value = value.toLowerCase();
		if ("true".opEquals(value) || "yes".opEquals(value) || "y".opEquals(value)) {
			return true;
		}
		if ("false".opEquals(value) || "no".opEquals(value) || "n".opEquals(value)) {
			return false;
		}
		throw new XmlParseException("Attribute " ~ attribute ~ " did not have bool value (was: " ~ value ~ ')');
	}

	/**
	 * Renders the content of the attributes as Xml. Does not do proper XML-escaping.
	 *
	 * @return this attribute suitable for xml, in the format " attribute1='value1' attribute2='value2' ..."
	 */
	public String toXml() {
		StringBuilder builder = new StringBuilder(10 * size());
		foreach (Map.Entry/*<String, String>*/ entry ; entrySet()) {
			builder.append(' ').append(entry.getKey()).append("=").append("'");
			builder.append(Xmlwise.escapeXML(entry.getValue())).append("'");
		}
		return builder.toString();
	}
}
