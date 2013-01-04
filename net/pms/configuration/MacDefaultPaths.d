module net.pms.configuration.MacDefaultPaths;

import net.pms.util.PropertiesUtil;

import org.apache.commons.lang.StringUtils : isNotBlank;

class MacDefaultPaths : ProgramPaths {
	override
	public String getEac3toPath() {
		return null;
	}

	override
	public String getFfmpegPath() {
		return getBinariesPath() ~ "osx/ffmpeg";
	}

	override
	public String getFlacPath() {
		return getBinariesPath() ~ "osx/flac";
	}

	override
	public String getMencoderPath() {
		return getBinariesPath() ~ "osx/mencoder";
	}

	override
	public String getMplayerPath() {
		return getBinariesPath() ~ "osx/mplayer";
	}

	override
	public String getTsmuxerPath() {
		return getBinariesPath() ~ "osx/tsMuxeR";
	}

	override
	public String getVlcPath() {
		return "/Applications/VLC.app/Contents/MacOS/VLC";
	}

	override
	public String getDCRaw() {
		return getBinariesPath() ~ "osx/dcraw";
	}
	
	override
	public String getIMConvertPath() {
		return getBinariesPath() ~ "osx/convert";
	}

	/**
	 * Returns the path where binaries can be found. This path differs between
	 * the build phase and the test phase. The path will end with a slash unless
	 * it is empty.
	 *
	 * @return The path for binaries.
	 */
	private String getBinariesPath() {
		String path = PropertiesUtil.getProjectProperties().get("project.binaries.dir");

		if (isNotBlank(path)) {
			if (path.endsWith("/")) {
				return path;
			} else {
				return path ~ "/";
			}
		} else {
			return "";
		}
	}
}
