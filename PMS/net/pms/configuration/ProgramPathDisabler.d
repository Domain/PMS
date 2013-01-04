module net.pms.configuration.ProgramPathDisabler;

class ProgramPathDisabler : ProgramPaths {
	private bool disableVlc = false;
	private bool disableMencoder = false;
	private bool disableFfmpeg = false;
	private bool disableMplayer = false;
	private bool disableDCraw = false;
	private bool disableIMConvert = false;
	private ProgramPaths ifEnabled;

	public this(ProgramPaths ifEnabled) {
		this.ifEnabled = ifEnabled;
	}

	override
	public String getEac3toPath() {
		return ifEnabled.getEac3toPath();
	}

	override
	public String getFfmpegPath() {
		return disableFfmpeg ? null : ifEnabled.getFfmpegPath();
	}

	override
	public String getFlacPath() {
		return ifEnabled.getFlacPath();
	}

	override
	public String getMencoderPath() {
		return disableMencoder ? null : ifEnabled.getMencoderPath();
	}

	override
	public String getMplayerPath() {
		return disableMplayer ? null : ifEnabled.getMplayerPath();
	}

	override
	public String getTsmuxerPath() {
		return ifEnabled.getTsmuxerPath();
	}

	override
	public String getVlcPath() {
		return disableVlc ? null : ifEnabled.getVlcPath();
	}

	public void disableVlc() {
		disableVlc = true;
	}

	public void disableMencoder() {
		disableMencoder = true;
	}

	public void disableFfmpeg() {
		disableFfmpeg = true;
	}

	public void disableMplayer() {
		disableMplayer = true;
	}

	override
	public String getDCRaw() {
		return disableDCraw ? null : ifEnabled.getDCRaw();
	}
	
	override
	public String getIMConvertPath() {
		return disableIMConvert ? null : ifEnabled.getIMConvertPath();
	}
}
