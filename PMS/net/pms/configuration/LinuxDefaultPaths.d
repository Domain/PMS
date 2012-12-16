module net.pms.configuration.LinuxDefaultPaths;

import net.pms.util.PropertiesUtil;

import java.io.File;

import static org.apache.commons.lang.StringUtils.isNotBlank;

class LinuxDefaultPaths : ProgramPaths {
    private final String BINARIES_SEARCH_PATH = getBinariesSearchPath();

	override
	public String getEac3toPath() {
		return null;
	}

	override
	public String getFfmpegPath() {
		return getBinaryPath("ffmpeg");
	}

	override
	public String getFlacPath() {
		return getBinaryPath("flac");
	}

	override
	public String getMencoderPath() {
		return getBinaryPath("mencoder");
	}

	override
	public String getMplayerPath() {
		return getBinaryPath("mplayer");
	}

	override
	public String getTsmuxerPath() {
		return getBinaryPath("tsMuxeR");
	}

	override
	public String getVlcPath() {
		return getBinaryPath("vlc");
	}

	override
	public String getDCRaw() {
		return getBinaryPath("dcraw");
	}
	
	override
	public String getIMConvertPath() {
		return getBinaryPath("convert");
	}

	/**
	 * Returns the path where binaries can be found. This path differs between
	 * the build phase and the test phase. The path will end with a slash unless
	 * it is empty.
	 *
	 * @return The path for binaries.
	 */
	private String getBinariesSearchPath() {
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

    /**
     * Returns the path to requested binary tool.
     * Either absolute if executable found in project.binaries.dir or
     * short to search in system-wide  PATH.
     *
     * @param tool The name of binary tool
     * @return Path to binary
     */
    private String getBinaryPath(String tool) {
        File f = new File(BINARIES_SEARCH_PATH + tool);
        if (f.canExecute()) {
            return BINARIES_SEARCH_PATH + tool;
        } else {
            return tool;
        }
    }
}
