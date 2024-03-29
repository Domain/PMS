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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA  02110-1301, USA.
 */
module net.pms.encoders.PlayerFactory;

import java.util.List;
import java.io.File;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;

import net.pms.PMS;
import net.pms.configuration.PmsConfiguration;
import net.pms.dlna.DLNAResource;
import net.pms.formats.Format;
import net.pms.formats.FormatFactory;
import net.pms.io.SystemUtils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.sun.jna.Platform;

/**
 * This class handles players. Creating an instance will initialize the list of
 * known players.
 *
 * @since 1.51.0
 */
public final class PlayerFactory {
	/**
	 * Logger used for all logging.
	 */
	private static immutable Logger LOGGER = LoggerFactory
			.getLogger!FormatFactory();

	/**
	 * List of registered and approved {@link Player} objects.
	 */
	private static ArrayList/*<Player>*/ players = new ArrayList/*<Player>*/();

	/**
	 * List of registered {@link Player} objects.
	 */
	private static ArrayList/*<Player>*/ allPlayers = new ArrayList/*<Player>*/();

	/**
	 * Interface to Windows specific functions, like Windows Registry. The
	 * registry is set by the constructor.
	 */
	private static SystemUtils utils;

	/**
	 * This takes care of sorting the players by the given PMS configuration.
	 */
	private static class PlayerSort : Comparator/*<Player>*/ {
		private PmsConfiguration configuration;

		this(PmsConfiguration configuration) {
			this.configuration = configuration;
		}

		override
		public int compare(Player player1, Player player2) {
			List/*<String>*/ prefs = configuration.getEnginesAsList(PMS.get().getRegistry());
			Integer index1 = prefs.indexOf(player1.id());
			Integer index2 = prefs.indexOf(player2.id());

			// Not being in the configuration settings will sort the player as last.
			if (index1 == -1) {
				index1 = 999;
			}

			if (index2 == -1) {
				index2 = 999;
			}

			return index1.compareTo(index2);
		}
	}

	/**
	 * This class is not meant to be instantiated.
	 */
	private this() {
	}

	/**
	 * Constructor that registers all players based on the given configuration,
	 * frame and registry.
	 * 
	 * @param configuration The PMS configuration.
	 */
	public static void initialize(const PmsConfiguration configuration) {
		utils = PMS.get().getRegistry();
		registerPlayers(configuration);
	}

	/**
	 * Register a known set of audio or video transcoders.
	 * 
	 * @param configuration
	 *            PMS configuration settings.
	 */
	private static void registerPlayers(const PmsConfiguration configuration) {
		// TODO make these constructors consistent: pass configuration to all or to none
		if (Platform.isWindows()) {
			registerPlayer(new FFMpegAviSynthVideo());
		}

		registerPlayer(new FFMpegAudio(configuration));
		registerPlayer(new MEncoderVideo(configuration));

		if (Platform.isWindows()) {
			registerPlayer(new MEncoderAviSynth(configuration));
		}

		registerPlayer(new FFMpegVideo());
		registerPlayer(new MPlayerAudio(configuration));
		registerPlayer(new FFMpegWebVideo(configuration));
		registerPlayer(new MEncoderWebVideo(configuration));
		registerPlayer(new MPlayerWebVideoDump(configuration));
		registerPlayer(new MPlayerWebAudio(configuration));
		registerPlayer(new TSMuxerVideo(configuration));
		registerPlayer(new TsMuxerAudio(configuration));
		registerPlayer(new VideoLanAudioStreaming(configuration));
		registerPlayer(new VideoLanVideoStreaming(configuration));

		if (Platform.isWindows()) {
			registerPlayer(new FFMpegDVRMSRemux());
		}

		registerPlayer(new RAWThumbnailer());

		// Sort the players according to the configuration settings
		Collections.sort(allPlayers, new PlayerSort(configuration));
		Collections.sort(players, new PlayerSort(configuration));
	}

	/**
	 * Adds a single {@link Player} to the list of Players. Before the player is
	 * added to the list, it is verified to be okay.
	 * 
	 * @param player Player to be added to the list.
	 */
	public static synchronized void registerPlayer(const Player player) {
		bool ok = false;
		allPlayers.add(player);

		if (Player.NATIVE.opEquals(player.executable())) {
			ok = true;
		} else {
			if (Platform.isWindows()) {
				if (player.executable() is null) {
					LOGGER.info("Executable of transcoder profile " ~ player
							~ " not defined");
					return;
				}

				File executable = new File(player.executable());
				File executable2 = new File(player.executable() ~ ".exe");

				if (executable.exists() || executable2.exists()) {
					ok = true;
				} else {
					LOGGER.info("Executable of transcoder profile " ~ player
							~ " not found");
					return;
				}

				if (player.avisynth()) {
					ok = false;

					if (utils.isAvis()) {
						ok = true;
					} else {
						LOGGER.info("Transcoder profile " ~ player
								~ " will not be used because AviSynth was not found");
					}
				}
			} else if (!player.avisynth()) {
				ok = true;
			}
		}

		if (ok) {
			LOGGER.info("Registering transcoding engine: " ~ player);
			players.add(player);
		}
	}

	/**
	 * Returns the list of all players. This includes the ones not verified as
	 * being okay.
	 * 
	 * @return The list of players.
	 */
	public static ArrayList/*<Player>*/ getAllPlayers() {
		return allPlayers;
	}

	/**
	 * Returns the list of players that have been verified as okay.
	 * 
	 * @return The list of players.
	 */
	public static ArrayList/*<Player>*/ getPlayers() {
		return players;
	}

	/**
	 * @deprecated Use {@link #getPlayer(DLNAResource)} instead.
	 *
	 * Returns the player that matches the given class and format.
	 * 
	 * @param profileClass
	 *            The class to match.
	 * @param ext
	 *            The format to match.
	 * @return The player if a match could be found, <code>null</code>
	 *         otherwise.
	 */
	deprecated
	public static Player getPlayer(immutable Class/*<? : Player>*/ profileClass,
			immutable Format ext) {

		foreach (Player player ; players) {
			if (player.getClass().opEquals(profileClass)
					&& player.type() == ext.getType()
					&& !player.excludeFormat(ext)) {
				return player;
			}
		}

		return null;
	}

	/**
	 * Returns the first {@link Player} that matches the given mediaInfo or
	 * format. Each of the available players is passed the provided information
	 * and the first that reports it is compatible will be returned.
	 * 
	 * @param resource
	 *            The {@link DLNAMediaResource} to match
	 * @return The player if a match could be found, <code>null</code>
	 *         otherwise.
	 * @since 1.60.0
	 */
	public static Player getPlayer(immutable DLNAResource resource) {
		if (resource is null) {
			return null;
		}

		List/*<String>*/ enabledEngines = PMS.getConfiguration().getEnginesAsList(PMS.get().getRegistry());

		foreach (Player player ; players) {
			if (enabledEngines.contains(player.id()) && player.isCompatible(resource)) {
				// Player is enabled and compatible
				LOGGER.trace("Selecting player " ~ player.name() ~ " for resource " ~ resource.getName());
				return player;
			} 
		}

		return null;
	}

	/**
	 * @deprecated Use {@link #getPlayer(DLNAResource)} instead. 
	 *
	 * Returns the players matching the given classes and type.
	 * 
	 * @param profileClasses
	 *            The classes to match.
	 * @param type
	 *            The type to match.
	 * @return The list of players that match. If no players match, an empty
	 *         list is returned.
	 */
	deprecated
	public static ArrayList/*<Player>*/ getPlayers(
			immutable ArrayList/*<Class<? : Player>>*/ profileClasses,
			immutable int type) {

		ArrayList/*<Player>*/ compatiblePlayers = new ArrayList/*<Player>*/();

		foreach (Player player ; players) {
			if (profileClasses.contains(player.getClass())
					&& player.type() == type) {
				compatiblePlayers.add(player);
			}
		}

		return compatiblePlayers;
	}

	/**
	 * Returns all {@link Player}s that match the given resource and are
	 * enabled. Each of the available players is passed the provided information
	 * and each player that reports it is compatible will be returned.
	 * 
	 * @param resource
	 *				The {@link DLNAResource} to match
	 * @return The list of compatible players if a match could be found,
	 *				<code>null</code> otherwise.
	 * @since 1.60.0
	 */
	public static ArrayList/*<Player>*/ getPlayers(immutable DLNAResource resource) {
		if (resource is null) {
			return null;
		}

		List/*<String>*/ enabledEngines = PMS.getConfiguration().getEnginesAsList(PMS.get().getRegistry());
		ArrayList/*<Player>*/ compatiblePlayers = new ArrayList/*<Player>*/();
		
		foreach (Player player ; players) {
			if (enabledEngines.contains(player.id()) && player.isCompatible(resource)) {
				// Player is enabled and compatible
				LOGGER.trace("Player " ~ player.name() ~ " is compatible with resource " ~ resource.getName());
				compatiblePlayers.add(player);
			}
		}

		return compatiblePlayers;
	}

	/**
	 * @deprecated Use {@link #getPlayers(DLNAResource)} instead.
	 *
	 * @param resource The resource to match
	 * @return The list of players if a match could be found, null otherwise.
	 */
	deprecated
	public static ArrayList/*<Player>*/ getEnabledPlayers(immutable DLNAResource resource) {
		return getPlayers(resource);
	}
}
