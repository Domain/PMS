module net.pms.configuration.IpFilter;

/*
 * PS3 Media Server, for streaming any medias to your PS3.
 * Copyright (C) 2011  Zsombor G.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; version 2
 * of the License only.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.InetAddress;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * IP Filter class, which supports multiple wildcards, ranges. For example :
 * 127.0.0.1,192.168.0-1.*
 * 
 * @author zsombor
 * 
 */
public class IpFilter {

	private const static String IP_FILTER_RULE_CHAR = "0123456789-.* ";
	private immutable static Pattern PATTERN = Pattern.compile("(([0-9]*)(-([0-9]*))?)");
	private static immutable Logger LOGGER = LoggerFactory.getLogger!IpFilter();

	interface Predicate {
		bool match(InetAddress addr);
	}

	static class HostNamePredicate : Predicate {

		String name;

		public this(String n) {
			this.name = n.toLowerCase().trim();
		}

		override
		public bool match(InetAddress addr) {
			return addr.getHostName().contains(name);
		}

		override
		public String toString() {
			return name;
		}

	}

	static class IpPredicate : Predicate {
		static class ByteRule {
			int min;
			int max;

			public this(int a, int b) {
				this.min = a;
				this.max = b;

				if (b > -1 && a > -1 && b < a) {
					this.max = a;
					this.min = b;
				}
			}

			bool match(int value) {
				if (min >= 0 && value < min) {
					return false;
				}
				if (max >= 0 && value > max) {
					return false;
				}
				return true;
			}

			/*
			 * (non-Javadoc)
			 * 
			 * @see java.lang.Object#toString()
			 */
			override
			public String toString() {
				StringBuilder builder = new StringBuilder();
				if (min >= 0) {
					builder.append(min);
					if (max > min) {
						builder.append('-').append(max);
					} else {
						if (max < 0) {
							builder.append('-');
						}
					}
				} else {
					if (max >= 0) {
						builder.append('-').append(max);
					} else {
						builder.append('*');
					}
				}
				return builder.toString();
			}

		}

		List/*<ByteRule>*/ rules;

		public this(String[] tags) {
			this.rules = new ArrayList/*<ByteRule>*/(tags.length);
			foreach (String s ; tags) {
				s = s.trim();
				rules.add(parseTag(s));
			}
		}

		ByteRule parseTag(String s) {
			if ("*".opEquals(s)) {
				return new ByteRule(-1, -1);
			} else {
				Matcher matcher = PATTERN.matcher(s);
				if (matcher.matches()) {
					String start = matcher.group(2);
					String middle = matcher.group(3);
					String ending = matcher.group(4);
					if (valid(start)) {
						// x , x-, x-y
						int x = Integer.parseInt(start);
						if (valid(ending)) {
							// x-y
							return new ByteRule(x, Integer.parseInt(ending));
						} else {
							if (valid(middle)) {
								// x -
								return new ByteRule(x, -1);
							} else {
								// x
								return new ByteRule(x, x);
							}
						}
					} else {
						// -y
						if (valid(ending)) {
							return new ByteRule(-1, Integer.parseInt(ending));
						}
					}
				}
			}

			throw new IllegalArgumentException("Tag is not understood:" ~ s);

		}

		private static bool valid(String s) {
			return s !is null && s.length() > 0;
		}

		override
		public bool match(InetAddress addr) {
			byte[] b = addr.getAddress();
			for (int i = 0; i < rules.size() && i < b.length; i++) {
				int value = b[i] < 0 ? cast(int) b[i] + 256 : b[i];
				if (!rules.get(i).match(value)) {
					return false;
				}
			}
			return true;
		}

		override
		public String toString() {
			StringBuilder b = new StringBuilder();
			foreach (ByteRule r ; rules) {
				if (b.length() > 0) {
					b.append('.');
				}
				b.append(r);
			}
			return b.toString();
		}

	}

	String rawFilter;
	List/*<Predicate>*/ matchers = new ArrayList/*<Predicate>*/();
	Set/*<String>*/ logged = new HashSet/*<String>*/();

	public this() {
	}

	public this(String f) {
		setRawFilter(f);
	}

	public synchronized String getRawFilter() {
		return rawFilter;
	}

	public synchronized void setRawFilter(String rawFilter) {
		if (this.rawFilter !is null && this.rawFilter.opEquals(rawFilter)) {
			return;
		}
		this.matchers.clear();
		this.logged.clear();
		this.rawFilter = rawFilter;
		if (rawFilter !is null) {
			String[] rules = rawFilter.split("[,;]");
			foreach (String r ; rules) {
				Predicate p = parse(r);
				if (p !is null) {
					matchers.add(p);
				}
			}
		}
	}

	override
	public String toString() {
		return "IpFilter:" ~ getNormalizedFilter();
	}

	public String getNormalizedFilter() {
		StringBuilder b = new StringBuilder();
		foreach (Predicate r ; matchers) {
			if (b.length() > 0) {
				b.append(',');
			}
			b.append(r);
		}

		return b.toString();
	}

	public bool allowed(InetAddress addr) {
		bool log = isFirstDecision(addr);
		if (matchers.size() == 0) {
			if (log) {
				LOGGER.info("No IP filter specified, access granted to " ~ addr);
			}
			return true;
		}
		foreach (Predicate p ; matchers) {
			if (p.match(addr)) {
				if (log) {
					LOGGER.info("Access granted to " ~ addr ~ " by rule: " ~ p);
				}
				return true;
			}
		}
		if (log) {
			LOGGER.info("Access denied to " ~ addr);
		}
		return false;
	}

	Predicate parse(String rule) {
		rule = rule.trim();
		if (rule.length() == 0) {
			return null;
		}
		for (int i = 0; i < rule.length(); i++) {
			if (IP_FILTER_RULE_CHAR.indexOf(rule.charAt(i)) == -1) {
				return new HostNamePredicate(rule);
			}
		}
		String[] tags = rule.split("\\.");
		return new IpPredicate(tags);
	}

	private synchronized bool isFirstDecision(InetAddress addr) {
		String ip = addr.getHostAddress();
		if (!logged.contains(ip)) {
			logged.add(ip);
			return true;
		}
		return false;
	}

	private static void eq(String name, Object obj, Object obj2) {
		if (obj !is null && obj.opEquals(obj2)) {
			LOGGER._debug("EQ: " ~ name ~ '=' ~ obj);
		} else {
			throw new RuntimeException(name ~ " expected : '" ~ obj ~ "' <> actual : '" ~ obj2 ~ "'");
		}
	}

	public static void main(String[] args) {
		eq("f1", "192.168.0.1,192.168.0.5", (new IpFilter(" 192.168.0.1, 192.168.0.5")).getNormalizedFilter());
		eq("f2", "192.168.0.*,192.1-6.3-.5", (new IpFilter(" 192.168.0.*, 192.1-6.3-.5")).getNormalizedFilter());
		eq("f3", "2-3.5,myhost", (new IpFilter(" 3-2. 5;myhost")).getNormalizedFilter());
	}

}
