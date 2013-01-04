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
module net.pms.encoders.MEncoderAviSynth;

//import com.jgoodies.forms.builder.PanelBuilder;
//import com.jgoodies.forms.factories.Borders;
//import com.jgoodies.forms.layout.CellConstraints;
//import com.jgoodies.forms.layout.FormLayout;
import net.pms.Messages;
import net.pms.PMS;
import net.pms.configuration.PmsConfiguration;
import net.pms.dlna.DLNAResource;
import net.pms.formats.Format;

////import javax.swing.*;
////import java.awt.*;
//import java.awt.event.ItemEvent;
//import java.awt.event.ItemListener;
//import java.awt.event.KeyEvent;
//import java.awt.event.KeyListener;
import java.util.StringTokenizer;

public class MEncoderAviSynth : MEncoderVideo {
	public this(PmsConfiguration configuration) {
		super(configuration);
	}

	private JTextArea textArea;
	private JCheckBox convertfps;

	override
	public JComponent config() {
		FormLayout layout = new FormLayout(
			"left:pref, 0:grow",
			"p, 3dlu, p, 3dlu, p, 3dlu,  0:grow");
		PanelBuilder builder = new PanelBuilder(layout);
		builder.setBorder(Borders.EMPTY_BORDER);
		builder.setOpaque(false);

		CellConstraints cc = new CellConstraints();


		JComponent cmp = builder.addSeparator(Messages.getString("MEncoderAviSynth.2"), cc.xyw(2, 1, 1));
		cmp = cast(JComponent) cmp.getComponent(0);
		cmp.setFont(cmp.getFont().deriveFont(Font.BOLD));

		convertfps = new JCheckBox(Messages.getString("MEncoderAviSynth.3"));
		convertfps.setContentAreaFilled(false);
		if (PMS.getConfiguration().getAvisynthConvertFps()) {
			convertfps.setSelected(true);
		}
		convertfps.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				PMS.getConfiguration().setAvisynthConvertFps((e.getStateChange() == ItemEvent.SELECTED));
			}
		});
		builder.add(convertfps, cc.xy(2, 3));

		String clip = PMS.getConfiguration().getAvisynthScript();
		if (clip is null) {
			clip = "";
		}
		StringBuilder sb = new StringBuilder();
		StringTokenizer st = new StringTokenizer(clip, PMS.AVS_SEPARATOR);
		int i = 0;
		while (st.hasMoreTokens()) {
			if (i > 0) {
				sb.append("\n");
			}
			sb.append(st.nextToken());
			i++;
		}
		textArea = new JTextArea(sb.toString());
		textArea.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				StringBuilder sb = new StringBuilder();
				StringTokenizer st = new StringTokenizer(textArea.getText(), "\n");
				int i = 0;
				while (st.hasMoreTokens()) {
					if (i > 0) {
						sb.append(PMS.AVS_SEPARATOR);
					}
					sb.append(st.nextToken());
					i++;
				}
				PMS.getConfiguration().setAvisynthScript(sb.toString());
			}
		});

		JScrollPane pane = new JScrollPane(textArea, JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED, JScrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED);
		pane.setPreferredSize(new Dimension(500, 350));
		builder.add(pane, cc.xy(2, 5));


		return builder.getPanel();
	}

	override
	public int purpose() {
		return VIDEO_SIMPLEFILE_PLAYER;
	}
	public static const String ID = "avsmencoder";

	override
	public String id() {
		return ID;
	}

	override
	public bool avisynth() {
		return true;
	}

	override
	public String name() {
		return "AviSynth/MEncoder";
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public bool isCompatible(DLNAResource resource) {
		if (resource is null || resource.getFormat().getType() != Format.VIDEO) {
			return false;
		}

		Format format = resource.getFormat();

		if (format !is null) {
			Format.Identifier id = format.getIdentifier();

			if (id.opEquals(Format.Identifier.MKV)
					|| id.opEquals(Format.Identifier.MPG)) {
				return true;
			}
		}

		return false;
	}
}
