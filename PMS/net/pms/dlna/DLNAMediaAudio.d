/*
 * PS3 Media Server, for streaming any medias to your PS3.
 * Copyright (C) 2008  A.Brochard
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
module net.pms.dlna.DLNAMediaAudio;

import net.pms.formats.v2.AudioProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This class keeps track of the audio properties of media.
 * 
 * TODO: Change all instance variables to private. For backwards compatibility
 * with external plugin code the variables have all been marked as deprecated
 * instead of changed to private, but this will surely change in the future.
 * When everything has been changed to private, the deprecated note can be
 * removed.
 */
public class DLNAMediaAudio : DLNAMediaLang , Cloneable {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!DLNAMediaAudio();
	private AudioProperties audioProperties = new AudioProperties();

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public int bitsperSample;


    private int bitRate;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String sampleFrequency;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public int nrAudioChannels;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String codecA;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String album;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String artist;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String songname;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String genre;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public int year;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public int track;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public int delay;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String flavor;

	/**
	 * @deprecated Use standard getter and setter to access this variable.
	 */
	deprecated
	public String muxingModeAudio;

	/**
	 * Constructor
	 */
	public this() {
		setBitsperSample(16);
	}

	/**
	 * Returns the sample rate for this audio media.
	 * 
	 * @return The sample rate.
	 */
	public int getSampleRate() {
		int sr = 0;
		if (getSampleFrequency() !is null && getSampleFrequency().length() > 0) {
			try {
				sr = Integer.parseInt(getSampleFrequency());
			} catch (NumberFormatException e) {
				LOGGER._debug("Could not parse sample rate from \"" ~ getSampleFrequency() ~ "\"");
			}
		}
		return sr;
	}

	/**
	 * Returns true if this media uses the AC3 audio codec, false otherwise.
	 * 
	 * @return True if the AC3 audio codec is used.
	 */
	public bool isAC3() {
		return getCodecA() !is null && (getCodecA().equalsIgnoreCase("ac3") || getCodecA().equalsIgnoreCase("a52") || getCodecA().equalsIgnoreCase("liba52"));
	}

	/**
	 * Returns true if this media uses the TrueHD audio codec, false otherwise.
	 * 
	 * @return True if the TrueHD audio codec is used.
	 */
	public bool isTrueHD() {
		return getCodecA() !is null && getCodecA().equalsIgnoreCase("truehd");
	}

	/**
	 * Returns true if this media uses the DTS audio codec, false otherwise.
	 * 
	 * @return True if the DTS audio codec is used.
	 */
	public bool isDTS() {
		return getCodecA() !is null && (getCodecA().startsWith("dts") || getCodecA().equalsIgnoreCase("dca") || getCodecA().equalsIgnoreCase("dca (dts)"));
	}

	/**
	 * Returns true if this media uses an AC3, DTS or TrueHD codec, false otherwise.
	 * 
	 * @return True if the AC3, DTS or TrueHD codec is used.
	 */
	public bool isNonPCMEncodedAudio() {
		return isAC3() || isDTS() || isTrueHD();
	}

	/**
	 * Returns true if this media uses the MP3 audio codec, false otherwise.
	 * 
	 * @return True if the MP3 audio codec is used.
	 */
	public bool isMP3() {
		return getCodecA() !is null && getCodecA().equalsIgnoreCase("mp3");
	}

	/**
	 * Returns true if this media uses the AAC audio codec, false otherwise.
	 *
	 * @return True if the AAC audio codec is used.
	 */
	public bool isAAC() {
		return getCodecA() !is null && getCodecA().equalsIgnoreCase("aac");
	}

	/**
	 * Returns true if this media uses the Ogg Vorbis audio codec, false otherwise.
	 *
	 * @return True if the Ogg Vorbis audio codec is used.
	 */
	public bool isVorbis() {
		return getCodecA() !is null && getCodecA().equalsIgnoreCase("vorbis");
	}

	/**
	 * Returns true if this media uses the WMA audio codec, false otherwise.
	 *
	 * @return True if the WMA audio codec is used.
	 */
	public bool isWMA() {
		return getCodecA() !is null && getCodecA().startsWith("wm");
	}

	/**
	 * Returns true if this media uses the Mpeg Audio audio codec, false otherwise.
	 *
	 * @return True if the Mpeg Audio audio codec is used.
	 */
	public bool isMpegAudio() {
		return getCodecA() !is null && getCodecA().equalsIgnoreCase("mp2");
	}

	/**
	 * Returns true if this media uses audio that is PCM encoded, false otherwise.
	 * 
	 * @return True if the audio is PCM encoded.
	 */
	public bool isPCM() {
		return getCodecA() !is null && (getCodecA().startsWith("pcm") || getCodecA().opEquals("LPCM"));
	}

	/**
	 * Returns true if this media uses a lossless audio compression codec, false otherwise.
	 * 
	 * @return True if the audio is lossless compressed.
	 */
	public bool isLossless() {
		return getCodecA() !is null && (isPCM() || getCodecA().startsWith("fla") || getCodecA().opEquals("mlp") || getCodecA().opEquals("wv"));
	}

	/**
	 * Returns a standardized name for the audio codec that is used.
	 * 
	 * @return The standardized name.
	 */
	public String getAudioCodec() {
		if (isAC3()) {
			return "AC3";
		} else if (isDTS()) {
			return "DTS";
		} else if (isTrueHD()) {
			return "TrueHD";
		} else if (isPCM()) {
			return "LPCM";
		} else if (getCodecA() !is null && getCodecA().opEquals("vorbis")) {
			return "OGG";
		} else if (getCodecA() !is null && getCodecA().opEquals("aac")) {
			return "AAC";
		} else if (getCodecA() !is null && getCodecA().opEquals("mp3")) {
			return "MP3";
		} else if (getCodecA() !is null && getCodecA().startsWith("wm")) {
			return "WMA";
		} else if (getCodecA() !is null && getCodecA().opEquals("mp2")) {
			return "Mpeg Audio";
		}
		return getCodecA() !is null ? getCodecA() : "-";
	}

	/**
	 * Returns the identifying name for the audio properties.
	 * 
	 * @return The name.
	 */
	public String toString() {
		return "Audio: " ~ getAudioCodec() ~ " / lang: " ~ getLang() ~ " / flavor: " ~ getFlavor() ~ " / ID: " ~ getId();
	}

	override
	protected Object clone() {
		return super.clone();
	}

	/**
	 * Returns the number of bits per sample for the audio.
	 * 
	 * @return The number of bits per sample.
	 * @since 1.50.0
	 */
	public int getBitsperSample() {
		return bitsperSample;
	}

	/**
	 * Sets the number of bits per sample for the audio.
	 * 
	 * @param bitsperSample The number of bits per sample to set.
	 * @since 1.50.0
	 */
	public void setBitsperSample(int bitsperSample) {
		this.bitsperSample = bitsperSample;
	}

    /**
     * Returns audio bitrate.
     *
     * @return Audio bitrate.
     * @since 1.54.0
     */
    public int getBitRate() {
        return bitRate;
    }

    /**
     * Sets audio bitrate.
     *
     * @param bitRate Audio bitrate to set.
     * @since 1.54.0
     */
    public void setBitRate(int bitRate) {
        this.bitRate = bitRate;
    }

	/**
	 * Returns the sample frequency for the audio.
	 * 
	 * @return The sample frequency.
	 * @since 1.50.0
	 */
	public String getSampleFrequency() {
		return sampleFrequency;
	}

	/**
	 * Sets the sample frequency for the audio.
	 * 
	 * @param sampleFrequency The sample frequency to set.
	 * @since 1.50.0
	 */
	public void setSampleFrequency(String sampleFrequency) {
		this.sampleFrequency = sampleFrequency;
	}

	/**
	 * Returns the number of channels for the audio.
	 * 
	 * @return The number of channels
	 * @since 1.50.0
	 * @deprecated Use getAudioProperties().getNumberOfChannels() instead
	 */
	deprecated
	public int getNrAudioChannels() {
		return audioProperties.getNumberOfChannels();
	}

	/**
	 * Sets the number of channels for the audio.
	 * 
	 * @param numberOfChannels The number of channels to set.
	 * @since 1.50.0
	 * @deprecated Use getAudioProperties().setNumberOfChannels(int numberOfChannels) instead
	 */
	deprecated
	public void setNrAudioChannels(int numberOfChannels) {
		this.nrAudioChannels = numberOfChannels;
		audioProperties.setNumberOfChannels(numberOfChannels);
	}

	/**
	 * Returns the name of the audio codec that is being used.
	 * 
	 * @return The name of the audio codec.
	 * @since 1.50.0
	 */
	public String getCodecA() {
		return codecA;
	}

	/**
	 * Sets the name of the audio codec that is being used.
	 * 
	 * @param codecA The name of the audio codec to set.
	 * @since 1.50.0
	 */
	public void setCodecA(String codecA) {
		this.codecA = codecA;
	}

	/**
	 * Returns the name of the album to which an audio track belongs.
	 * 
	 * @return The album name.
	 * @since 1.50.0
	 */
	public String getAlbum() {
		return album;
	}

	/**
	 * Sets the name of the album to which an audio track belongs.
	 * 
	 * @param album The name of the album to set.
	 * @since 1.50.0
	 */
	public void setAlbum(String album) {
		this.album = album;
	}

	/**
	 * Returns the name of the artist performing the audio track.
	 * 
	 * @return The artist name.
	 * @since 1.50.0
	 */
	public String getArtist() {
		return artist;
	}

	/**
	 * Sets the name of the artist performing the audio track.
	 * 
	 * @param artist The artist name to set.
	 * @since 1.50.0
	 */
	public void setArtist(String artist) {
		this.artist = artist;
	}

	/**
	 * Returns the name of the song for the audio track.
	 * 
	 * @return The song name.
	 * @since 1.50.0
	 */
	public String getSongname() {
		return songname;
	}

	/**
	 * Sets the name of the song for the audio track.
	 * 
	 * @param songname The song name to set.
	 * @since 1.50.0
	 */
	public void setSongname(String songname) {
		this.songname = songname;
	}

	/**
	 * Returns the name of the genre for the audio track.
	 * 
	 * @return The genre name.
	 * @since 1.50.0
	 */
	public String getGenre() {
		return genre;
	}

	/**
	 * Sets the name of the genre for the audio track.
	 * 
	 * @param genre The name of the genre to set.
	 * @since 1.50.0
	 */
	public void setGenre(String genre) {
		this.genre = genre;
	}

	/**
	 * Returns the year of inception for the audio track.
	 * 
	 * @return The year.
	 * @since 1.50.0
	 */
	public int getYear() {
		return year;
	}

	/**
	 * Sets the year of inception for the audio track.
	 * 
	 * @param year The year to set.
	 * @since 1.50.0
	 */
	public void setYear(int year) {
		this.year = year;
	}

	/**
	 * Returns the track number within an album for the audio.
	 * 
	 * @return The track number.
	 * @since 1.50.0
	 */
	public int getTrack() {
		return track;
	}

	/**
	 * Sets the track number within an album for the audio.
	 * 
	 * @param track The track number to set.
	 * @since 1.50.0
	 */
	public void setTrack(int track) {
		this.track = track;
	}

	/**
	 * Returns the delay for the audio.
	 * 
	 * @return The delay.
	 * @since 1.50.0
	 * @deprecated Use getAudioProperties().getAudioDelay() instead
	 */
	deprecated
	public int getDelay() {
		return audioProperties.getAudioDelay();
	}

	/**
	 * Sets the delay for the audio.
	 * 
	 * @param audioDelay The delay to set.
	 * @since 1.50.0
	 * @deprecated  Use getAudioProperties().setAudioDelay(int audioDelay) instead
	 */
	deprecated
	public void setDelay(int audioDelay) {
		this.delay = audioDelay;
		audioProperties.setAudioDelay(audioDelay);
	}

	/**
	 * Returns the flavor for the audio.
	 * 
	 * @return The flavor.
	 * @since 1.50.0
	 */
	public String getFlavor() {
		return flavor;
	}

	/**
	 * Sets the flavor for the audio.
	 * 
	 * @param flavor The flavor to set.
	 * @since 1.50.0
	 */
	public void setFlavor(String flavor) {
		this.flavor = flavor;
	}

	/**
	 * Returns the audio codec to use for muxing.
	 * 
	 * @return The audio codec to use.
	 * @since 1.50.0
	 */
	public String getMuxingModeAudio() {
		return muxingModeAudio;
	}

	/**
	 * Sets the audio codec to use for muxing.
	 * 
	 * @param muxingModeAudio The audio codec to use.
	 * @since 1.50.0
	 */
	public void setMuxingModeAudio(String muxingModeAudio) {
		this.muxingModeAudio = muxingModeAudio;
	}

	public AudioProperties getAudioProperties() {
		return audioProperties;
	}

	public void setAudioProperties(AudioProperties audioProperties) {
		if (audioProperties is null) {
			throw new IllegalArgumentException("Can't set null AudioProperties.");
		}
		this.audioProperties = audioProperties;
	}
}
