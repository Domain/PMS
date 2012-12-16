module net.pms.configuration.WindowsDefaultPaths;

import net.pms.util.PropertiesUtil;

import static org.apache.commons.lang.StringUtils.isNotBlank;

class WindowsDefaultPaths : ProgramPaths {
	override
	public String getEac3toPath() {
		return getBinariesPath() + "win32/eac3to/eac3to.exe";
	}

	override
	public String getFfmpegPath() {
		return getBinariesPath() + "win32/ffmpeg.exe";
	}

	override
	public String getFlacPath() {
		return getBinariesPath() + "win32/flac.exe";
	}

	override
	public String getMencoderPath() {
		return getBinariesPath() + "win32/mencoder.exe";
	}

	override
	public String getMplayerPath() {
		return getBinariesPath() + "win32/mplayer.exe";
	}

	override
	public String getTsmuxerPath() {
		return getBinariesPath() + "win32/tsMuxeR.exe";
	}

	override
	public String getVlcPath() {
		return getBinariesPath() +  "videolan/vlc.exe";
	}

	override
	public String getDCRaw() {
		return getBinariesPath() + "win32/dcrawMS.exe";
	}
	
	override
	public String getIMConvertPath() {
		return getBinariesPath() + "win32/convert.exe";
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
				return path + "/";
			}
		} else {
			return "";
		}
	}
}
