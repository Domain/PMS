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
module net.pms.newgui.AboutTab;

//import com.jgoodies.forms.builder.PanelBuilder;
//import com.jgoodies.forms.layout.CellConstraints;
//import com.jgoodies.forms.layout.FormLayout;
import net.pms.Messages;
import net.pms.PMS;
import net.pms.util.PropertiesUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.imageio.ImageIO;
////import javax.swing.*;
////import java.awt.*;
//import java.awt.event.MouseEvent;
//import java.awt.event.MouseListener;
//import java.awt.image.BufferedImage;
import java.lang.exceptions;

public class AboutTab {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!AboutTab();

	private ImagePanel imagePanel;
	private JLabel jl;
	private JProgressBar jpb;

	public JProgressBar getJpb() {
		return jpb;
	}

	public JLabel getJl() {
		return jl;
	}

	public ImagePanel getImagePanel() {
		return imagePanel;
	}

	public JComponent build() {
		FormLayout layout = new FormLayout(
			"0:grow, pref, 0:grow",
			"pref, 3dlu, pref, 3dlu, pref, 12dlu, pref, 3dlu, pref, 3dlu, pref, 3dlu, pref, 3dlu, p, 3dlu, p");

		PanelBuilder builder = new PanelBuilder(layout);
		builder.setDefaultDialogBorder();
		builder.setOpaque(true);
		CellConstraints cc = new CellConstraints();

		String projectName = PropertiesUtil.getProjectProperties().get("project.name");

		LinkMouseListener pms3Link = new LinkMouseListener(projectName + " " + PMS.getVersion(),
			"http://www.ps3mediaserver.org/");
		JLabel lPms3Link = builder.addLabel(pms3Link.getLabel(), cc.xy(2, 1, "center, fill"));
		lPms3Link.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
		lPms3Link.addMouseListener(pms3Link);

		// Create a build name from the available git properties
		String commitId = PropertiesUtil.getProjectProperties().get("git.commit.id");
		String commitTime = PropertiesUtil.getProjectProperties().get("git.commit.time");
		String shortCommitId = commitId.substring(0,  9);
		String commitUrl = "https://github.com/ps3mediaserver/ps3mediaserver/commit/" + commitId;
		String buildLabel = Messages.getString("LinksTab.6") + " " + shortCommitId + " (" + commitTime + ")";

		LinkMouseListener commitLink = new LinkMouseListener(buildLabel, commitUrl);
		JLabel lCommitLink = builder.addLabel(commitLink.getLabel(), cc.xy(2, 3, "center, fill"));
		lCommitLink.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
		lCommitLink.addMouseListener(commitLink);

		imagePanel = buildImagePanel();
		builder.add(imagePanel, cc.xy(2, 5, "center, fill"));


		builder.addLabel(Messages.getString("LinksTab.5"), cc.xy(2, 7, "center, fill"));

		LinkMouseListener ffmpegLink = new LinkMouseListener("FFmpeg",
			"http://ffmpeg.mplayerhq.hu");
		JLabel lFfmpegLink = builder.addLabel(ffmpegLink.getLabel(), cc.xy(2, 9, "center, fill"));
		lFfmpegLink.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
		lFfmpegLink.addMouseListener(ffmpegLink);

		LinkMouseListener mplayerLink = new LinkMouseListener("MPlayer",
			"http://www.mplayerhq.hu");
		JLabel lMplayerLink = builder.addLabel(mplayerLink.getLabel(), cc.xy(2, 11, "center, fill"));
		lMplayerLink.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
		lMplayerLink.addMouseListener(mplayerLink);

		LinkMouseListener mplayerSubJunkBuildsLink = new LinkMouseListener("SubJunk's MPlayer builds",
			"http://www.spirton.com/mplayer-mencoder-subjunk-build/");
		JLabel lMplayerSubJunkBuildsLink = builder.addLabel(mplayerSubJunkBuildsLink.getLabel(), cc.xy(2, 13, "center, fill"));
		lMplayerSubJunkBuildsLink.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
		lMplayerSubJunkBuildsLink.addMouseListener(mplayerSubJunkBuildsLink);

		LinkMouseListener mediaInfoLink = new LinkMouseListener("MediaInfo",
			"http://mediainfo.sourceforge.net/en");
		JLabel lMediaInfoLink = builder.addLabel(mediaInfoLink.getLabel(), cc.xy(2, 15, "center, fill"));
		lMediaInfoLink.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
		lMediaInfoLink.addMouseListener(mediaInfoLink);

		JScrollPane scrollPane = new JScrollPane(builder.getPanel());
		scrollPane.setBorder(BorderFactory.createEmptyBorder());
		return scrollPane;
	}

	private static class LinkMouseListener : MouseListener {
		private final String name;
		private final String link;

		public this(String n, String l) {
			name = n;
			link = l;
		}

		public String getLabel() {
			StringBuilder sb = new StringBuilder();
			sb.append("<html>");
			sb.append("<a href=\"");
			sb.append(link);
			sb.append("\">");
			sb.append(name);
			sb.append("</a>");
			sb.append("</html>");
			return sb.toString();
		}

		override
		public void mouseClicked(MouseEvent e) {
			try {
				PMS.get().getRegistry().browseURI(link);
			} catch (Exception e1) {
				LOGGER._debug("Caught exception", e1);
			}
		}

		override
		public void mouseEntered(MouseEvent e) {
		}

		override
		public void mouseExited(MouseEvent e) {
		}

		override
		public void mousePressed(MouseEvent e) {
		}

		override
		public void mouseReleased(MouseEvent e) {
		}
	}

	public ImagePanel buildImagePanel() {
		BufferedImage bi = null;
		try {
			bi = ImageIO.read(LooksFrame._class.getResourceAsStream("/resources/images/logo.png"));
		} catch (IOException e) {
			LOGGER._debug("Caught exception", e);
		}
		return new ImagePanel(bi);
	}
}
