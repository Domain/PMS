module net.pms.configuration.ConfigurationProgramPaths;

import org.apache.commons.configuration.Configuration;

class ConfigurationProgramPaths : ProgramPaths {
	private static const String KEY_VLC_PATH                 = "vlc_path";
	private static const String KEY_EAC3TO_PATH              = "eac3to_path";
	private static const String KEY_MENCODER_PATH            = "mencoder_path";
	private static const String KEY_FFMPEG_PATH              = "ffmpeg_path";
	private static const String KEY_MPLAYER_PATH             = "mplayer_path";
	private static const String KEY_TSMUXER_PATH             = "tsmuxer_path";
	private static const String KEY_FLAC_PATH                = "flac_path";
	private static const String KEY_DCRAW                    = "dcraw_path";
	private static const String KEY_IMCONVERT_PATH           = "imconvert_path";

	private Configuration configuration;
	private ProgramPaths defaults;

	public this(Configuration configuration, ProgramPaths defaults) {
		this.configuration = configuration;
		this.defaults = defaults;
	}

	override
	public String getEac3toPath() {
		return getString(KEY_EAC3TO_PATH, defaults.getEac3toPath());
	}

	override
	public String getFfmpegPath() {
		return getString(KEY_FFMPEG_PATH, defaults.getFfmpegPath());
	}

	override
	public String getFlacPath() {
		return getString(KEY_FLAC_PATH, defaults.getFlacPath());
	}

	override
	public String getMencoderPath() {
		return getString(KEY_MENCODER_PATH, defaults.getMencoderPath());
	}

	override
	public String getMplayerPath() {
		return getString(KEY_MPLAYER_PATH, defaults.getMplayerPath());
	}

	override
	public String getTsmuxerPath() {
		return getString(KEY_TSMUXER_PATH, defaults.getTsmuxerPath());
	}

	override
	public String getVlcPath() {
		return getString(KEY_VLC_PATH, defaults.getVlcPath());
	}

	/**
	 * Return the <code>String</code> value for a given configuration key if the
	 * value is non-blank (i.e. not null, not an empty string, not all whitespace).
	 * Otherwise return the supplied default value.
	 * The value is returned with leading and trailing whitespace removed in both cases.
	 * @param key The key to look up.
	 * @param def The default value to return when no valid key value can be found.
	 * @return The value configured for the key.
	 */
	private String getString(String key, String def) {
		return ConfigurationUtil.getNonBlankConfigurationString(configuration, key, def);
	}

	override
	public String getDCRaw() {
		return getString(KEY_DCRAW, defaults.getDCRaw());
	}
	
	override
	public String getIMConvertPath() {
		return getString(KEY_IMCONVERT_PATH, defaults.getIMConvertPath());
	}
}
