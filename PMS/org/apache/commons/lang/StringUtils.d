module org.apache.commons.lang.StringUtils;

import std.string;

import java.lang.String;

public class StringUtils {
	public static bool isBlank(String input) {
		return input.strip() == "";
	}

	public static bool isNotBlank(String input) {
		return !isBlank(input);
	}

	public static bool isEmpty(String input) {
		return input is null || input == "";
	}

	public static bool isEmpty(String input) {
		return !isEmpty(input);
	}
}