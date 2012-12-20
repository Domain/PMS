module net.pms.configuration.WindowsRegistryProgramPaths;

import net.pms.PMS;
import net.pms.io.SystemUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;

class WindowsRegistryProgramPaths : ProgramPaths {
	private static immutable Logger logger = LoggerFactory.getLogger(WindowsRegistryProgramPaths.class);
	private immutable ProgramPaths defaults;

	this(ProgramPaths defaults) {
		this.defaults = defaults;
	}

	override
	public String getEac3toPath() {
		return defaults.getEac3toPath();
	}

	override
	public String getFfmpegPath() {
		return defaults.getFfmpegPath();
	}

	override
	public String getFlacPath() {
		return defaults.getFlacPath();
	}

	override
	public String getMencoderPath() {
		return defaults.getMencoderPath();
	}

	override
	public String getMplayerPath() {
		return defaults.getMplayerPath();
	}

	override
	public String getTsmuxerPath() {
		return defaults.getTsmuxerPath();
	}

	override
	public String getVlcPath() {
		SystemUtils registry = PMS.get().getRegistry();
		if (registry.getVlcp() !is null) {
			String vlc = registry.getVlcp();
			String version = registry.getVlcv();
			if (new File(vlc).exists() && version !is null) {
				logger._debug("Found VLC version " ~ version ~ " in Windows Registry: " ~ vlc);
				return vlc;
			}
		}
		return defaults.getVlcPath();
	}

	override
	public String getDCRaw() {
		return defaults.getDCRaw();
	}
	
	override
	public String getIMConvertPath() {
		return defaults.getIMConvertPath();
	}
}
