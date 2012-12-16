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
module net.pms.newgui.MyComboBoxModel;

import javax.swing.*;

public class MyComboBoxModel : DefaultComboBoxModel {
	private static final long serialVersionUID = -9094365556516842551L;

	public MyComboBoxModel() {
		super();
	}

	public MyComboBoxModel(Object[] items) {
		super(items);
	}

	override
	public Object getElementAt(int index) {
		String s = (String) super.getElementAt(index);
		return s;
	}
}
