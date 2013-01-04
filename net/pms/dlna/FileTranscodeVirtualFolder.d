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
module net.pms.dlna.FileTranscodeVirtualFolder;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import net.pms.PMS;
import net.pms.configuration.RendererConfiguration;
import net.pms.dlna.virtual.VirtualFolder;
import net.pms.encoders.Player;
import net.pms.encoders.PlayerFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This class populates the file-specific transcode folder with content.
 */
public class FileTranscodeVirtualFolder : VirtualFolder {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!FileTranscodeVirtualFolder();
	private bool resolved;

	/**
	 * Class to take care of sorting the resources correctly. Resources
	 * are sorted by player, then by audio track, then by subtitle.
	 */
	private class ResourceSort : Comparator/*<DLNAResource>*/ {
		private ArrayList/*<Player>*/ players;

		this(ArrayList/*<Player>*/ players) {
			this.players = players;
		}

		override
		public int compare(DLNAResource resource1, DLNAResource resource2) {
			Integer playerIndex1 = players.indexOf(resource1.getPlayer());
			Integer playerIndex2 = players.indexOf(resource2.getPlayer());

			if (playerIndex1.opEquals(playerIndex2)) {
				String audioLang1 = resource1.getMediaAudio().getLang();
				String audioLang2 = resource2.getMediaAudio().getLang();

				if (audioLang1.opEquals(audioLang2)) {
					String subtitle1 = resource1.getMediaSubtitle().getLang();
					String subtitle2 = resource2.getMediaSubtitle().getLang();

					if (subtitle1 !is null && subtitle2 !is null) {
						return subtitle1.compareToIgnoreCase(subtitle2);
					} else {
						if (subtitle1 is null && subtitle2 is null) {
							return 0;
						} else {
							if (subtitle1 is null) {
								return -1;
							} else {
								return 1;
							}
						}
					}
				} else {
					return audioLang1.compareToIgnoreCase(audioLang2);
				}
			} else {
				return playerIndex1.compareTo(playerIndex2);
			}
		}
	}

	// FIXME unused
	deprecated
	public this(String name, String thumbnailIcon, bool copy) {
		super(name, thumbnailIcon);
	}

	public this(String name, String thumbnailIcon) { // XXX thumbnailIcon is always null
		super(name, thumbnailIcon);
	}

	private void addChapterFile(DLNAResource source) {
		if (PMS.getConfiguration().isChapterSupport() && PMS.getConfiguration().getChapterInterval() > 0) {
			ChapterFileTranscodeVirtualFolder chapterFolder = new ChapterFileTranscodeVirtualFolder(
				"Chapters:" ~ source.getDisplayName(),
				null,
				PMS.getConfiguration().getChapterInterval()
			);
			DLNAResource newSeekChild = source.clone();
			newSeekChild.setNoName(true);
			chapterFolder.addChildInternal(newSeekChild);
			addChildInternal(chapterFolder);
		}
	}

	/**
	 * This populates the file-specific transcode folder with all combinations of players,
	 * audio tracks and subtitles.
	 */
	override
	public void resolve() {
		super.resolve();

		if (!resolved && getChildren().size() == 1) { // OK
			DLNAResource child = getChildren().get(0);
			child.resolve();

			// First, add the option to simply stream the resource
			DLNAResource justStreamed = child.clone();

			RendererConfiguration renderer = null;

			if (this.getParent() !is null) {
				renderer = this.getParent().getDefaultRenderer();
			}

			// Only add the option if the renderer is compatible with the format
			if (justStreamed.getFormat() !is null
					&& (justStreamed.getFormat().isCompatible(child.getMedia(),
							renderer) || justStreamed.isSkipTranscode())) {
				justStreamed.setPlayer(null);
				justStreamed.setMedia(child.getMedia());
				justStreamed.setNoName(true);
				addChildInternal(justStreamed);
				addChapterFile(justStreamed);

				if (renderer !is null) {
					LOGGER._debug("Duplicate " ~ child.getName()
							~ " for direct streaming to renderer: "
							~ renderer.getRendererName());
				}
			}

			// List holding all combinations
			ArrayList/*<DLNAResource>*/ combos = new ArrayList/*<DLNAResource>*/();

			List/*<DLNAMediaAudio>*/ audioTracks = child.getMedia().getAudioTracksList();
			List/*<DLNAMediaSubtitle>*/ subtitles = child.getMedia().getSubtitleTracksList();

			// Make sure a combo with no subtitles will be added
			DLNAMediaSubtitle noSubtitle = new DLNAMediaSubtitle();
			noSubtitle.setId(-1);
			subtitles.add(noSubtitle);

			// Create combinations of all audio tracks, subtitles and players.
			foreach (DLNAMediaAudio audio ; audioTracks) {
				foreach (DLNAMediaSubtitle subtitle ; subtitles) {
					// Create a temporary copy of the child with the audio and
					// subtitle modified in order to be able to match players to it.
					DLNAResource tempModifiedCopy = createModifiedResource(child, audio, subtitle);

					// Determine which players match this audio track and subtitle
					ArrayList/*<Player>*/ players = PlayerFactory.getPlayers(tempModifiedCopy);

					foreach (Player player ; players) {
						// Create a copy based on this combination
						DLNAResource combo = createComboResource(child, audio, subtitle, player);
						combos.add(combo);
					}
				}
			}

			// Sort the list of combinations
			Collections.sort(combos, new ResourceSort(PlayerFactory.getAllPlayers()));

			// Now add the sorted list of combinations to the folder
			foreach (DLNAResource combo ; combos) {
				LOGGER.trace("Adding " ~ combo.toString() ~ " - "
						~ combo.getPlayer().name() ~ " - "
						~ combo.getMediaAudio().toString() ~ " - "
						~ combo.getMediaSubtitle().toString());

				addChildInternal(combo);
				addChapterFile(combo);
			}
		}

		resolved = true;
	}

	/**
	 * Create a copy of the provided original resource with the given audio
	 * track, subtitles and player.
	 *
	 * @param original The original {@link DLNAResource} to create a copy of.
	 * @param audio The audio track to use.
	 * @param subtitle The subtitle track to use.
	 * @param player The player to use.
	 * @return The copy.
	 */
	private DLNAResource createComboResource(
		DLNAResource original,
		DLNAMediaAudio audio,
		DLNAMediaSubtitle subtitle,
		Player player
	) {
		// FIXME: Use new DLNAResource() instead of clone(). Clone is bad, mmmkay?
		DLNAResource copy = original.clone();

		copy.setMedia(original.getMedia());
		copy.setNoName(true);
		copy.setMediaAudio(audio);
		copy.setMediaSubtitle(subtitle);
		copy.setPlayer(player);

		return copy;
	}

	/**
	 * Create a copy of the provided original resource and modify it with
	 * the given audio track and subtitles.
	 *
	 * @param original The original {@link DLNAResource} to create a copy of.
	 * @param audio The audio track to use.
	 * @param subtitle The subtitle track to use.
	 * @return The copy.
	 */
	private DLNAResource createModifiedResource(
		DLNAResource original,
		DLNAMediaAudio audio,
		DLNAMediaSubtitle subtitle
	) {
		// FIXME: Use new DLNAResource() instead of clone(). Clone is bad, mmmkay?
		DLNAResource copy = original.clone();

		copy.setMedia(original.getMedia());
		copy.setNoName(true);
		copy.setMediaAudio(audio);
		copy.setMediaSubtitle(subtitle);
		return copy;
	}
}
