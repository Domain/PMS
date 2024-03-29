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
module net.pms.newgui.TreeNodeSettings;

//import com.jgoodies.forms.builder.PanelBuilder;
//import com.jgoodies.forms.layout.CellConstraints;
//import com.jgoodies.forms.layout.FormLayout;
import net.pms.Messages;
import net.pms.encoders.Player;
import net.pms.encoders.PlayerFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.imageio.ImageIO;
////import javax.swing.*;
//import javax.swing.tree.DefaultMutableTreeNode;
////import java.awt.*;
//import java.awt.image.BufferedImage;
import java.lang.exceptions;

public class TreeNodeSettings : DefaultMutableTreeNode {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!TreeNodeSettings();
	private static const long serialVersionUID = -337606760204027449L;
	private Player p;
	private JComponent otherConfigPanel;
	private bool enable = true;
	private JPanel warningPanel;

	public bool isEnable() {
		return enable;
	}

	public void setEnable(bool enable) {
		this.enable = enable;

	}

	public Player getPlayer() {
		return p;
	}

	public this(String name, Player p, JComponent otherConfigPanel) {
		super(name);
		this.p = p;
		this.otherConfigPanel = otherConfigPanel;

	}

	public String id() {
		if (p !is null) {
			return p.id();
		} else if (otherConfigPanel !is null) {
			return otherConfigPanel.hashCode().toString();
		} else {
			return null;
		}
	}

	public JComponent getConfigPanel() {
		if (p !is null) {
			if (PlayerFactory.getPlayers().contains(p)) {
				return p.config();
			} else {
				return getWarningPanel();
			}
		} else if (otherConfigPanel !is null) {
			return otherConfigPanel;
		} else {
			return new JPanel();
		}
	}

	public JPanel getWarningPanel() {
		if (warningPanel is null) {
			BufferedImage bi = null;
			try {
				bi = ImageIO.read(LooksFrame._class.getResourceAsStream("/resources/images/messagebox_warning-220.png"));
			} catch (IOException e) {
				LOGGER._debug("Caught exception", e);
			}
			ImagePanel ip = new ImagePanel(bi);

			FormLayout layout = new FormLayout(
				"0:grow, pref, 0:grow",
				"pref, 3dlu, pref, 12dlu, pref, 3dlu, pref, 3dlu, p, 3dlu, p, 3dlu, p");

			PanelBuilder builder = new PanelBuilder(layout);
			builder.setDefaultDialogBorder();
			builder.setOpaque(false);
			CellConstraints cc = new CellConstraints();

			JLabel jl = new JLabel(Messages.getString("TreeNodeSettings.4"));
			builder.add(jl, cc.xy(2, 1, "center, fill"));
			jl.setFont(jl.getFont().deriveFont(Font.BOLD));

			builder.add(ip, cc.xy(2, 3, "center, fill"));

			warningPanel = builder.getPanel();
		}
		return warningPanel;
	}
}
