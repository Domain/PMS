/*
 * PS3 Media Server, for streaming any medias to your PS3.
 * Copyright (C) 2012  I. Sokolov
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
module net.pms.formats.v2.AudioAttribute;

import java.util.all;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang.StringUtils : isBlank;

/**
 * Enum with possible audio track attributes.
 * AUDIO_ATTRIBUTE (Set<String> libMediaInfoKeys, bool multipleValuesPossible,
 * bool getLargerValue, Integer defaultValue, Integer minimumValue)
 */
public class AudioAttribute {
	//enum Internal {
	//    CHANNELS_NUMBER (set("Channel(s)"), true, true, 2, 1),
	//    DELAY (set("Video_Delay"), false, false, 0, null),
	//    SAMPLE_FREQUENCY (set("SamplingRate"), true, true, 48000, 1);
	//}
	//
	//Internal internal;
	//alias internal this;
	
	private Set/*<String>*/ libMediaInfoKeys;
	private bool multipleValuesPossible;
	private bool getLargerValue;
	private Integer defaultValue;
	private Integer minimumValue;


	private static final Pattern libMediaInfoKeyPattern = Pattern.compile("^\\s*(\\S+)\\s*:");
	private final static Map/*<String, AudioAttribute>*/ libMediaInfoKeyToAudioAttributeMap;
	private static Set/*<String>*/ set(String[] args... ) {
		return new HashSet/*<String>*/(Arrays.asList(args));
	}

	static this() {
		libMediaInfoKeyToAudioAttributeMap = new HashMap/*<String, AudioAttribute>*/();
		foreach (AudioAttribute audioAttribute ; values()) {
			foreach (String libMediaInfoKey ; audioAttribute.libMediaInfoKeys) {
				libMediaInfoKeyToAudioAttributeMap.put(libMediaInfoKey.toLowerCase(), audioAttribute);
			}
		}
	}

	private this(Set/*<String>*/ libMediaInfoKeys, bool multipleValuesPossible,
						   bool getLargerValue, Integer defaultValue, Integer minimumValue) {
		this.libMediaInfoKeys = libMediaInfoKeys;
		this.multipleValuesPossible = multipleValuesPossible;
		this.getLargerValue = getLargerValue;
		this.defaultValue = defaultValue;
		this.minimumValue = minimumValue;
	}

	public static AudioAttribute getAudioAttributeByLibMediaInfoKeyValuePair(String keyValuePair) {
		if (isBlank(keyValuePair)) {
			throw new IllegalArgumentException("Empty keyValuePair passed in.");
		}

		Matcher keyMatcher = libMediaInfoKeyPattern.matcher(keyValuePair);
		if (keyMatcher.find()) {
			String key = keyMatcher.group(1);
			AudioAttribute audioAttribute = libMediaInfoKeyToAudioAttributeMap.get(key.toLowerCase());
			if (audioAttribute is null) {
				throw new IllegalArgumentException("Can't find AudioAttribute for key '" + key + "'.");
			} else {
				return audioAttribute;
			}
		} else {
			throw new IllegalArgumentException("Can't find key in keyValuePair '" + keyValuePair + "'.");
		}
	}


	public Integer getDefaultValue() {
		return defaultValue;
	}

	public bool isGetLargerValue() {
		return getLargerValue;
	}

	public bool isMultipleValuesPossible() {
		return multipleValuesPossible;
	}

	public Integer getMinimumValue() {
		return minimumValue;
	}
}
