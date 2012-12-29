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
module net.pms.newgui.TreeRenderer;

import net.pms.encoders.Player;
import net.pms.encoders.PlayerFactory;

////import javax.swing.*;
//import javax.swing.tree.DefaultTreeCellRenderer;
////import java.awt.*;

public class TreeRenderer : DefaultTreeCellRenderer {
	private static const long serialVersionUID = 8830634234336247114L;

	public this() {
	}

	public Component getTreeCellRendererComponent(
		JTree tree,
		Object value,
		bool sel,
		bool expanded,
		bool leaf,
		int row,
		bool hasFocus
	) {

		super.getTreeCellRendererComponent(
			tree, value, sel,
			expanded, leaf, row,
			hasFocus);
		if (leaf && cast(TreeNodeSettings)value !is null) {
			if ((cast(TreeNodeSettings) value).getPlayer() is null) {
				setIcon(LooksFrame.readImageIcon("icon_tree_parent-16.png"));
			} else {
				if ((cast(TreeNodeSettings) value).isEnable()) {
					Player p = (cast(TreeNodeSettings) value).getPlayer();
					if (PlayerFactory.getPlayers().contains(p)) {
						setIcon(LooksFrame.readImageIcon("icon_tree_node-16.png"));
					} else {
						setIcon(LooksFrame.readImageIcon("messagebox_warning-16.png"));
					}
				} else {
					setIcon(LooksFrame.readImageIcon("icon_tree_node_fail-16.png"));
				}
			}

			if ((cast(TreeNodeSettings) value).getPlayer() !is null && (cast(TreeNodeSettings) value).getParent().getIndex(cast(TreeNodeSettings) value) == 0) {
				setFont(getFont().deriveFont(Font.BOLD));
			} else {
				setFont(getFont().deriveFont(Font.PLAIN));
			}
		} else {
			setIcon(LooksFrame.readImageIcon("icon_tree_parent-16.png"));
		}
		return this;
	}
}
