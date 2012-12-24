module net.pms.xmlwise.XmlElement;

import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import java.util.LinkedList;

/**
 * A simplified XML Element that only has an attribute map, a list of sub elements a text value and
 * a name.
 * <p>
 * This is the basic entity of the xmlwise library.
 *
 * @author Christoffer Lerno
 */
public class XmlElement : LinkedList/*<XmlElement>*/ {
	private XmlElementAttributes m_attributes;
	private String m_value;
	private String m_name;

	/**
	 * Creates a new XmlElement given an Element object.
	 *
	 * @param element the document element to construct this object from.
	 */
	public this(Element element) {
		m_attributes = new XmlElementAttributes(element);
		NodeList children = element.getChildNodes();
		m_name = element.getNodeName();
		StringBuilder textValue = new StringBuilder();
		for (int i = 0; i < children.getLength(); i++) {
			Node node = children.item(i);
			if (node.getNodeType() == Node.ELEMENT_NODE) {
				add(new XmlElement(cast(Element) node));
			}
			if (node.getNodeType() == Node.TEXT_NODE) {
				textValue.append(node.getNodeValue());
			}
		}
		m_value = textValue.toString();
	}

	/**
	 * Creates a new XmlElement with the given name and inner text value.
	 *
	 * @param name the name of the node.
	 * @param value the inner text value of the node.
	 */
	public this(String name, String value) {
		m_attributes = new XmlElementAttributes();
		m_name = name;
		m_value = value;
	}

	/**
	 * Creates a new XmlElement with the given name with no inner text.
	 *
	 * @param name the name of the node.
	 */
	public this(String name) {
		m_attributes = new XmlElementAttributes();
		m_name = name;
		m_value = "";
	}

	/**
	 * Get the single direct sub-element with the given name.
	 *
	 * @param name the name of the sub-element.
	 * @return the sub element.
	 * @throws XmlParseException if there are more than one of the sub element, or if no such element was found.
	 */
	public XmlElement getUnique(final String name) {
		LinkedList/*<XmlElement>*/ matches = get(name);
		if (matches.size() != 1) {
			throw new XmlParseException("Unexpected number of elements of type " ~ name ~ " in element <" ~ getName() ~ ">");
		}
		return matches.getFirst();
	}

	/**
	 * Get an integer attribute for this element.
	 *
	 * @param attribute the name of the attribute.
	 * @return the integer value of the attribute.
	 * @throws XmlParseException if we fail to parse this attribute as an int, or the attribute is missing.
	 */
	public int getIntAttribute(String attribute) {
		return getAttributes().getInt(attribute);
	}

	/**
	 * Get an integer attribute for this element, defaulting to a default value if the attribute is missing.
	 *
	 * @param attribute the name of the attribute.
	 * @param defaultValue the default value for the attribute, returned if the attribute is missing.
	 * @return the integer value of the attribute or the default value if the attribute is missing.
	 * @throws XmlParseException if we fail to parse this attribute as an int.
	 */
	public int getIntAttribute(String attribute, int defaultValue) {
		return containsAttribute(attribute) ? getIntAttribute(attribute) : defaultValue;
	}

	/**
	 * Get a double attribute for this element.
	 *
	 * @param attribute the name of the attribute.
	 * @return the double value of the attribute.
	 * @throws XmlParseException if we fail to parse this attribute as an double, or the attribute is missing.
	 */
	public double getDoubleAttribute(String attribute) {
		return getAttributes().getDouble(attribute);
	}

	/**
	 * Get an double attribute for this element, defaulting to a default value if the attribute is missing.
	 *
	 * @param attribute the name of the attribute.
	 * @param defaultValue the default value for the attribute, returned if the attribute is missing.
	 * @return the double value of the attribute or the default value if the attribute is missing.
	 * @throws XmlParseException if we fail to parse this attribute as an double.
	 */
	public double getDoubleAttribute(String attribute, double defaultValue) {
		return containsAttribute(attribute) ? getDoubleAttribute(attribute) : defaultValue;
	}

	/**
	 * Get a (string) attribute for this element, defaulting to a default value if the attribute is missing.
	 *
	 * @param attribute the name of the attribute.
	 * @param defaultValue the default value for the attribute, returned if the attribute is missing.
	 * @return the value of the attribute or the default value if the attribute is missing.
	 */
	public String getAttribute(String attribute, String defaultValue) {
		String value = getAttribute(attribute);
		return value is null ? defaultValue : value;
	}

	/**
	 * Returns the (string) value of an attribute.
	 *
	 * @param attribute the attribute name.
	 * @return the value of the attribute.
	 */
	public String getAttribute(String attribute) {
		return getAttributes().get(attribute);
	}

	/**
	 * Get an bool attribute for this element.
	 * <p>
	 * "true", "yes" and "y" are all interpreted as true. (Case-independent)
	 * <p>
	 * "false", "no" and "no" are all interpreted at false. (Case-independent)
	 *
	 * @param attribute the name of the attribute.
	 * @return the bool value of the attribute.
	 * @throws XmlParseException if the attribute value does match true or false as defined, or the attribute is missing.
	 */
	public bool getBoolAttribute(String attribute) {
		return getAttributes().getBoolean(attribute);
	}

	/**
	 * Get an bool attribute for this element, defaulting to the default value if missing.
	 * <p>
	 * "true", "yes" and "y" are all interpreted as true. (Case-independent)
	 * <p>
	 * "false", "no" and "no" are all interpreted at false. (Case-independent)
	 *
	 * @param attribute the name of the attribute.
	 * @param defaultValue the default value of the attribute.
	 * @return the bool value of the attribute or the default value if the attribute is missing.
	 * @throws XmlParseException if the attribute value does match true or false as defined
	 */
	public bool getBoolAttribute(String attribute, bool defaultValue) {
		return containsAttribute(attribute) ? getBoolAttribute(attribute) : defaultValue;
	}

	/**
	 * Get all elements matching the given key.
	 *
	 * @param name the key to match.
	 * @return a linked list of matching xml elements
	 */
	public LinkedList/*<XmlElement>*/ get(String name) {
		LinkedList/*<XmlElement>*/ list = new LinkedList/*<XmlElement>*/();
		foreach (XmlElement element ; this) {
			if (element.getName().opEquals(name)) {
				list.add(element);
			}
		}
		return list;
	}

	/**
	 * Convenience method to set an attribute on this
	 * element.
	 *
	 * @param attribute the attribute to set.
	 * @param value the new value of the attribute.
	 */
	public void setAttribute(String attribute, Object value) {
		m_attributes.put(attribute, value.toString());
	}

	/**
	 * Convenience method to remove an attribute from this element.
	 *
	 * @param attribute the attribute to remove.
	 * @return true if this attribute existed before it was removed,
	 * false otherwise.
	 */
	public bool removeAttribute(String attribute) {
		return m_attributes.remove(attribute) !is null;
	}

	/**
	 * Determines if a direct sub-element exists.
	 *
	 * @param key the name of the sub-element.
	 * @return true if the element exists, false otherwise.
	 */
	public bool contains(String key) {
		foreach (XmlElement element ; this) {
			if (element.getName().opEquals(key)) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Renders this as XML.
	 *
	 * @return an xml string based on this element and its sub-elements.
	 */
	public String toXml() {
		StringBuilder builder = (new StringBuilder("<")).append(m_name);
		if (m_attributes.size() > 0) {
			builder.append(m_attributes.toXml());
		}
		if (isEmpty() && m_value.length() == 0) {
			builder.append("/>");
		} else {
			builder.append('>');
			builder.append(Xmlwise.escapeXML(m_value));
			foreach (XmlElement element ; this) {
				builder.append(element.toXml());
			}
			builder.append("</").append(m_name).append('>');
		}
		return builder.toString();
	}

	/**
	 * Get the string value contained in this element.
	 * <p>
	 * E.g. the element for <code>&lt;node&gt;foo&lt;/node&gt;</code>
	 * would return "foo" as its value.
	 * <p>
	 * Note that this value will be a concatenation of all strings
	 * directly inside the element, even if the element contains
	 * sub elements.
	 *
	 * @return the string value contained inside this element.
	 */
	public String getValue() {
		return m_value;
	}

	/**
	 * Returns a map with all attributes of this element.
	 *
	 * @return a map with the attributes for this element.
	 */
	public XmlElementAttributes getAttributes() {
		return m_attributes;
	}

	/**
	 * Returns the name of this element.
	 * <p>
	 * E.g. the element for <code>&lt;node&gt;foo&lt;/node&gt;</code>
	 * would return "node" as its name.
	 *
	 * @return the name of this element.
	 */
	public String getName() {
		return m_name;
	}

	/**
	 * Determines if an attribute exists.
	 * @param attribute the attribute to check.
	 * @return true if the attribute exists on this element, false otherwise.
	 */
	public bool containsAttribute(String attribute) {
		return getAttributes().containsKey(attribute);
	}
}
