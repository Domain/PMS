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
module net.pms.encoders.MEncoderVideo;

//import bsh.EvalError;
//import bsh.Interpreter;
//import com.jgoodies.forms.builder.PanelBuilder;
//import com.jgoodies.forms.factories.Borders;
//import com.jgoodies.forms.layout.CellConstraints;
//import com.jgoodies.forms.layout.FormLayout;
import com.sun.jna.Platform;
import net.pms.Messages;
import net.pms.PMS;
import net.pms.configuration.FormatConfiguration;
import net.pms.configuration.PmsConfiguration;
import net.pms.configuration.RendererConfiguration;
import net.pms.dlna.all;
import net.pms.formats.Format;
import net.pms.formats.v2.SubtitleType;
import net.pms.formats.v2.SubtitleUtils;
import net.pms.io.all;
import net.pms.network.HTTPResource;
import net.pms.newgui.FontFileFilter;
import net.pms.newgui.LooksFrame;
import net.pms.newgui.MyComboBoxModel;
import net.pms.newgui.RestrictedFileSystemView;
import net.pms.util.CodecUtil;
import net.pms.util.FileUtil;
import net.pms.util.FormLayoutUtil;
import net.pms.util.ProcessUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.lang.exceptions;
import java.io.PrintWriter;
import java.util.all;
import java.util.List;

import net.pms.formats.v2.AudioUtils : getLPCMChannelMappingForMencoder;
import org.apache.commons.lang.BooleanUtils : isTrue;
import org.apache.commons.lang.StringUtils : isBlank, isNotBlank, isEmpty, isNotEmpty;

public class MEncoderVideo : Player {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!MEncoderVideo();
	private static const String COL_SPEC = "left:pref, 3dlu, p:grow, 3dlu, right:p:grow, 3dlu, p:grow, 3dlu, right:p:grow,3dlu, p:grow, 3dlu, right:p:grow,3dlu, pref:grow";
	private static const String ROW_SPEC = "p, 2dlu, p, 2dlu, p, 2dlu, p, 2dlu, p, 2dlu, p, 2dlu, p, 2dlu,p, 2dlu, p, 2dlu, p, 2dlu, p, 2dlu, p, 9dlu, p, 2dlu, p, 2dlu, p , 2dlu, p, 2dlu, p, 2dlu, p, 2dlu, p, 2dlu, p, 2dlu, p, 2dlu, p, 2dlu, p, 2dlu, p, 2dlu, p";
	private static const String REMOVE_OPTION = "---REMOVE-ME---"; // use an out-of-band option that can't be confused with a real option

	private JTextField mencoder_ass_scale;
	private JTextField mencoder_ass_margin;
	private JTextField mencoder_ass_outline;
	private JTextField mencoder_ass_shadow;
	private JTextField mencoder_noass_scale;
	private JTextField mencoder_noass_subpos;
	private JTextField mencoder_noass_blur;
	private JTextField mencoder_noass_outline;
	private JTextField mencoder_custom_options;
	private JTextField langs;
	private JTextField defaultsubs;
	private JTextField forcedsub;
	private JTextField forcedtags;
	private JTextField defaultaudiosubs;
	private JTextField defaultfont;
	private JComboBox subcp;
	private JTextField subq;
	private JCheckBox forcefps;
	private JCheckBox yadif;
	private JCheckBox scaler;
	private JTextField scaleX;
	private JTextField scaleY;
	private JCheckBox assdefaultstyle;
	private JCheckBox fc;
	private JCheckBox ass;
	private JCheckBox checkBox;
	private JCheckBox mencodermt;
	private JCheckBox videoremux;
	private JCheckBox noskip;
	private JCheckBox intelligentsync;
	private JTextField alternateSubFolder;
	private JButton subColor;
	private JTextField ocw;
	private JTextField och;
	private JCheckBox subs;
	private JCheckBox fribidi;
	private immutable PmsConfiguration configuration;

	private static const String[] INVALID_CUSTOM_OPTIONS = [
		"-of",
		"-oac",
		"-ovc",
		"-mpegopts"
	];

	private static immutable String INVALID_CUSTOM_OPTIONS_LIST = Arrays.toString(INVALID_CUSTOM_OPTIONS);

	public static const int MENCODER_MAX_THREADS = 8;
	public static const String ID = "mencoder";

	// TODO (breaking change): most (probably all) of these
	// protected fields should be private. And at least two
	// shouldn't be fields

	deprecated
	protected bool dvd;

	deprecated
	protected String[] overriddenMainArgs;

	protected bool dtsRemux;
	protected bool pcm;
	protected bool ovccopy;
	protected bool ac3Remux;
	protected bool mpegts;
	protected bool wmv;

	public static immutable String DEFAULT_CODEC_CONF_SCRIPT =
		Messages.getString("MEncoderVideo.68")
		~ Messages.getString("MEncoderVideo.69")
		~ Messages.getString("MEncoderVideo.70")
		~ Messages.getString("MEncoderVideo.71")
		~ Messages.getString("MEncoderVideo.72")
		~ Messages.getString("MEncoderVideo.73")
		~ Messages.getString("MEncoderVideo.75")
		~ Messages.getString("MEncoderVideo.76")
		~ Messages.getString("MEncoderVideo.77")
		~ Messages.getString("MEncoderVideo.78")
		~ Messages.getString("MEncoderVideo.79")
		~ "#\n"
		~ Messages.getString("MEncoderVideo.80")
		~ "container == iso :: -nosync\n"
		~ "(container == avi || container == matroska) && vcodec == mpeg4 && acodec == mp3 :: -mc 0.1\n"
		~ "container == flv :: -mc 0.1\n"
		~ "container == mov :: -mc 0.1\n"
		~ "container == rm  :: -mc 0.1\n"
		~ "container == matroska && framerate == 29.97  :: -nomux -mc 0\n"
		~ "container == mp4 && vcodec == h264 :: -mc 0.1\n"
		~ "\n"
		~ Messages.getString("MEncoderVideo.87")
		~ Messages.getString("MEncoderVideo.88")
		~ Messages.getString("MEncoderVideo.89")
		~ Messages.getString("MEncoderVideo.91");

	public JCheckBox getCheckBox() {
		return checkBox;
	}

	public JCheckBox getNoskip() {
		return noskip;
	}

	public JCheckBox getSubs() {
		return subs;
	}

	public this(PmsConfiguration configuration) {
		this.configuration = configuration;
	}

	override
	public JComponent config() {
		// Apply the orientation for the locale
		Locale locale = new Locale(configuration.getLanguage());
		ComponentOrientation orientation = ComponentOrientation.getOrientation(locale);
		String colSpec = FormLayoutUtil.getColSpec(COL_SPEC, orientation);

		FormLayout layout = new FormLayout(colSpec, ROW_SPEC);
		PanelBuilder builder = new PanelBuilder(layout);
		builder.setBorder(Borders.EMPTY_BORDER);
		builder.setOpaque(false);

		CellConstraints cc = new CellConstraints();

		checkBox = new JCheckBox(Messages.getString("MEncoderVideo.0"));
		checkBox.setContentAreaFilled(false);

		if (configuration.getSkipLoopFilterEnabled()) {
			checkBox.setSelected(true);
		}

		checkBox.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				configuration.setSkipLoopFilterEnabled((e.getStateChange() == ItemEvent.SELECTED));
			}
		});

		JComponent cmp = builder.addSeparator(Messages.getString("MEncoderVideo.1"), FormLayoutUtil.flip(cc.xyw(1, 1, 15), colSpec, orientation));
		cmp = cast(JComponent) cmp.getComponent(0);
		cmp.setFont(cmp.getFont().deriveFont(Font.BOLD));

		mencodermt = new JCheckBox(Messages.getString("MEncoderVideo.35"));
		mencodermt.setContentAreaFilled(false);

		if (configuration.getMencoderMT()) {
			mencodermt.setSelected(true);
		}

		mencodermt.addActionListener(new class() ActionListener {
			override
			public void actionPerformed(ActionEvent e) {
				configuration.setMencoderMT(mencodermt.isSelected());
			}
		});

		mencodermt.setEnabled(Platform.isWindows() || Platform.isMac());

		builder.add(mencodermt, FormLayoutUtil.flip(cc.xy(1, 3), colSpec, orientation));
		builder.add(checkBox, FormLayoutUtil.flip(cc.xyw(3, 3, 12), colSpec, orientation));

		noskip = new JCheckBox(Messages.getString("MEncoderVideo.2"));
		noskip.setContentAreaFilled(false);

		if (configuration.isMencoderNoOutOfSync()) {
			noskip.setSelected(true);
		}

		noskip.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				configuration.setMencoderNoOutOfSync((e.getStateChange() == ItemEvent.SELECTED));
			}
		});

		builder.add(noskip, FormLayoutUtil.flip(cc.xy(1, 5), colSpec, orientation));

		JButton button = new JButton(Messages.getString("MEncoderVideo.29"));
		button.addActionListener(new class() ActionListener {
			override
			public void actionPerformed(ActionEvent e) {
				JPanel codecPanel = new JPanel(new BorderLayout());
				final JTextArea textArea = new JTextArea();
				textArea.setText(configuration.getCodecSpecificConfig());
				textArea.setFont(new Font("Courier", Font.PLAIN, 12));
				JScrollPane scrollPane = new JScrollPane(textArea);
				scrollPane.setPreferredSize(new java.awt.Dimension(900, 100));

				final JTextArea textAreaDefault = new JTextArea();
				textAreaDefault.setText(DEFAULT_CODEC_CONF_SCRIPT);
				textAreaDefault.setBackground(Color.WHITE);
				textAreaDefault.setFont(new Font("Courier", Font.PLAIN, 12));
				textAreaDefault.setEditable(false);
				textAreaDefault.setEnabled(configuration.isMencoderIntelligentSync());
				JScrollPane scrollPaneDefault = new JScrollPane(textAreaDefault);
				scrollPaneDefault.setPreferredSize(new java.awt.Dimension(900, 450));

				JPanel customPanel = new JPanel(new BorderLayout());
				intelligentsync = new JCheckBox(Messages.getString("MEncoderVideo.3"));
				intelligentsync.setContentAreaFilled(false);

				if (configuration.isMencoderIntelligentSync()) {
					intelligentsync.setSelected(true);
				}

				intelligentsync.addItemListener(new class() ItemListener {
					public void itemStateChanged(ItemEvent e) {
						configuration.setMencoderIntelligentSync((e.getStateChange() == ItemEvent.SELECTED));
						textAreaDefault.setEnabled(configuration.isMencoderIntelligentSync());

					}
				});

				JLabel label = new JLabel(Messages.getString("MEncoderVideo.33"));
				customPanel.add(label, BorderLayout.NORTH);
				customPanel.add(scrollPane, BorderLayout.SOUTH);

				codecPanel.add(intelligentsync, BorderLayout.NORTH);
				codecPanel.add(scrollPaneDefault, BorderLayout.CENTER);
				codecPanel.add(customPanel, BorderLayout.SOUTH);

				while (JOptionPane.showOptionDialog(SwingUtilities.getWindowAncestor(cast(Component) PMS.get().getFrame()),
					codecPanel, Messages.getString("MEncoderVideo.34"), JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE, null, null, null) == JOptionPane.OK_OPTION) {
					String newCodecparam = textArea.getText();
					DLNAMediaInfo fakemedia = new DLNAMediaInfo();
					DLNAMediaAudio audio = new DLNAMediaAudio();
					audio.setCodecA("ac3");
					fakemedia.setCodecV("mpeg4");
					fakemedia.setContainer("matroska");
					fakemedia.setDuration(45*60);
					audio.getAudioProperties().setNumberOfChannels(2);
					fakemedia.setWidth(1280);
					fakemedia.setHeight(720);
					audio.setSampleFrequency("48000");
					fakemedia.setFrameRate("23.976");
					fakemedia.getAudioTracksList().add(audio);
					String result[] = getSpecificCodecOptions(newCodecparam, fakemedia, new OutputParams(configuration), "dummy.mpg", "dummy.srt", false, true);

					if (result.length > 0 && result[0].startsWith("@@")) {
						String errorMessage = result[0].substring(2);
						JOptionPane.showMessageDialog(
							SwingUtilities.getWindowAncestor(cast(Component) PMS.get().getFrame()),
							errorMessage,
							Messages.getString("Dialog.Error"),
							JOptionPane.ERROR_MESSAGE
						);
					} else {
						configuration.setCodecSpecificConfig(newCodecparam);
						break;
					}
				}
			}
		});

		builder.add(button, FormLayoutUtil.flip(cc.xyw(1, 11, 2), colSpec, orientation));

		forcefps = new JCheckBox(Messages.getString("MEncoderVideo.4"));
		forcefps.setContentAreaFilled(false);

		if (configuration.isMencoderForceFps()) {
			forcefps.setSelected(true);
		}

		forcefps.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				configuration.setMencoderForceFps(e.getStateChange() == ItemEvent.SELECTED);
			}
		});

		builder.add(forcefps, FormLayoutUtil.flip(cc.xyw(1, 7, 2), colSpec, orientation));

		yadif = new JCheckBox(Messages.getString("MEncoderVideo.26"));
		yadif.setContentAreaFilled(false);

		if (configuration.isMencoderYadif()) {
			yadif.setSelected(true);
		}

		yadif.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				configuration.setMencoderYadif(e.getStateChange() == ItemEvent.SELECTED);
			}
		});

		builder.add(yadif, FormLayoutUtil.flip(cc.xyw(3, 7, 7), colSpec, orientation));

		scaler = new JCheckBox(Messages.getString("MEncoderVideo.27"));
		scaler.setContentAreaFilled(false);
		scaler.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				configuration.setMencoderScaler(e.getStateChange() == ItemEvent.SELECTED);
				scaleX.setEnabled(configuration.isMencoderScaler());
				scaleY.setEnabled(configuration.isMencoderScaler());
			}
		});

		builder.add(scaler, FormLayoutUtil.flip(cc.xyw(3, 5, 7), colSpec, orientation));

		builder.addLabel(Messages.getString("MEncoderVideo.28"), FormLayoutUtil.flip(cc.xyw(10, 5, 3, CellConstraints.RIGHT, CellConstraints.CENTER), colSpec, orientation));
		scaleX = new JTextField(configuration.getMencoderScaleX().toString());
		scaleX.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				try {
					configuration.setMencoderScaleX(Integer.parseInt(scaleX.getText()));
				} catch (NumberFormatException nfe) {
					LOGGER._debug("Could not parse scaleX from \"" ~ scaleX.getText() ~ "\"");
				}
			}
		});

		builder.add(scaleX, FormLayoutUtil.flip(cc.xyw(13, 5, 3), colSpec, orientation));
		builder.addLabel(Messages.getString("MEncoderVideo.30"), FormLayoutUtil.flip(cc.xyw(10, 7, 3, CellConstraints.RIGHT, CellConstraints.CENTER), colSpec, orientation));
		scaleY = new JTextField(configuration.getMencoderScaleY().toString());
		scaleY.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				try {
					configuration.setMencoderScaleY(Integer.parseInt(scaleY.getText()));
				} catch (NumberFormatException nfe) {
					LOGGER._debug("Could not parse scaleY from \"" ~ scaleY.getText() ~ "\"");
				}
			}
		});

		builder.add(scaleY, FormLayoutUtil.flip(cc.xyw(13, 7, 3), colSpec, orientation));

		if (configuration.isMencoderScaler()) {
			scaler.setSelected(true);
		} else {
			scaleX.setEnabled(false);
			scaleY.setEnabled(false);
		}

		cmp = builder.addSeparator(Messages.getString("MEncoderVideo.5"), FormLayoutUtil.flip(cc.xyw(1, 19, 15), colSpec, orientation));
		cmp = cast(JComponent) cmp.getComponent(0);
		cmp.setFont(cmp.getFont().deriveFont(Font.BOLD));

		builder.addLabel(Messages.getString("MEncoderVideo.6"), FormLayoutUtil.flip(cc.xy(1, 21), colSpec, orientation));
		mencoder_custom_options = new JTextField(configuration.getMencoderCustomOptions());
		mencoder_custom_options.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderCustomOptions(mencoder_custom_options.getText());
			}
		});

		builder.add(mencoder_custom_options, FormLayoutUtil.flip(cc.xyw(3, 21, 13), colSpec, orientation));
		builder.addLabel(Messages.getString("MEncoderVideo.7"), FormLayoutUtil.flip(cc.xyw(1, 23, 15), colSpec, orientation));

		langs = new JTextField(configuration.getMencoderAudioLanguages());
		langs.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderAudioLanguages(langs.getText());
			}
		});

		builder.add(langs, FormLayoutUtil.flip(cc.xyw(3, 23, 8), colSpec, orientation));

		cmp = builder.addSeparator(Messages.getString("MEncoderVideo.8"), FormLayoutUtil.flip(cc.xyw(1, 25, 15), colSpec, orientation));
		cmp = cast(JComponent) cmp.getComponent(0);
		cmp.setFont(cmp.getFont().deriveFont(Font.BOLD));

		builder.addLabel(Messages.getString("MEncoderVideo.9"), FormLayoutUtil.flip(cc.xy(1, 27), colSpec, orientation));

		defaultsubs = new JTextField(configuration.getMencoderSubLanguages());
		defaultsubs.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderSubLanguages(defaultsubs.getText());
			}
		});

		builder.addLabel(Messages.getString("MEncoderVideo.94"), FormLayoutUtil.flip(cc.xy(5, 27), colSpec, orientation));

		forcedsub = new JTextField(configuration.getMencoderForcedSubLanguage());
		forcedsub.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderForcedSubLanguage(forcedsub.getText());
			}
		});

		builder.addLabel(Messages.getString("MEncoderVideo.95"), FormLayoutUtil.flip(cc.xy(9, 27), colSpec, orientation));
		forcedtags = new JTextField(configuration.getMencoderForcedSubTags());
		forcedtags.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderForcedSubTags(forcedtags.getText());
			}
		});

		builder.add(defaultsubs, FormLayoutUtil.flip(cc.xyw(3, 27, 2), colSpec, orientation));
		builder.add(forcedsub, FormLayoutUtil.flip(cc.xy(7, 27), colSpec, orientation));
		builder.add(forcedtags, FormLayoutUtil.flip(cc.xyw(11, 27, 5), colSpec, orientation));
		builder.addLabel(Messages.getString("MEncoderVideo.10"), FormLayoutUtil.flip(cc.xy(1, 29), colSpec, orientation));

		defaultaudiosubs = new JTextField(configuration.getMencoderAudioSubLanguages());
		defaultaudiosubs.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderAudioSubLanguages(defaultaudiosubs.getText());
			}
		});

		builder.add(defaultaudiosubs, FormLayoutUtil.flip(cc.xyw(3, 29, 8), colSpec, orientation));
		builder.addLabel(Messages.getString("MEncoderVideo.11"), FormLayoutUtil.flip(cc.xy(1, 31), colSpec, orientation));

		Object[] data = [
			configuration.getMencoderSubCp(),
			Messages.getString("MEncoderVideo.129"),
			Messages.getString("MEncoderVideo.130"),
			Messages.getString("MEncoderVideo.131"),
			Messages.getString("MEncoderVideo.132"),
			Messages.getString("MEncoderVideo.96"),
			Messages.getString("MEncoderVideo.97"),
			Messages.getString("MEncoderVideo.98"),
			Messages.getString("MEncoderVideo.99"),
			Messages.getString("MEncoderVideo.100"),
			Messages.getString("MEncoderVideo.101"),
			Messages.getString("MEncoderVideo.102"),
			Messages.getString("MEncoderVideo.103"),
			Messages.getString("MEncoderVideo.104"),
			Messages.getString("MEncoderVideo.105"),
			Messages.getString("MEncoderVideo.106"),
			Messages.getString("MEncoderVideo.107"),
			Messages.getString("MEncoderVideo.108"),
			Messages.getString("MEncoderVideo.109"),
			Messages.getString("MEncoderVideo.110"),
			Messages.getString("MEncoderVideo.111"),
			Messages.getString("MEncoderVideo.112"),
			Messages.getString("MEncoderVideo.113"),
			Messages.getString("MEncoderVideo.114"),
			Messages.getString("MEncoderVideo.115"),
			Messages.getString("MEncoderVideo.116"),
			Messages.getString("MEncoderVideo.117"),
			Messages.getString("MEncoderVideo.118"),
			Messages.getString("MEncoderVideo.119"),
			Messages.getString("MEncoderVideo.120"),
			Messages.getString("MEncoderVideo.121"),
			Messages.getString("MEncoderVideo.122"),
			Messages.getString("MEncoderVideo.123"),
			Messages.getString("MEncoderVideo.124")
		];

		MyComboBoxModel cbm = new MyComboBoxModel(data);
		subcp = new JComboBox(cbm);

		subcp.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				if (e.getStateChange() == ItemEvent.SELECTED) {
					String s = cast(String) e.getItem();
					int offset = s.indexOf("/*");

					if (offset > -1) {
						s = s.substring(0, offset).trim();
					}

					configuration.setMencoderSubCp(s);
				}
			}
		});
		subcp.getEditor().getEditorComponent().addKeyListener(new class() KeyListener {
			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				subcp.getItemListeners()[0].itemStateChanged(new ItemEvent(subcp, 0, subcp.getEditor().getItem(), ItemEvent.SELECTED));
			}
		});

		subcp.setEditable(true);
		builder.add(subcp, FormLayoutUtil.flip(cc.xyw(3, 31, 7), colSpec, orientation));

		fribidi = new JCheckBox(Messages.getString("MEncoderVideo.23"));
		fribidi.setContentAreaFilled(false);

		if (configuration.isMencoderSubFribidi()) {
			fribidi.setSelected(true);
		}

		fribidi.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				configuration.setMencoderSubFribidi(e.getStateChange() == ItemEvent.SELECTED);
			}
		});

		builder.add(fribidi, FormLayoutUtil.flip(cc.xyw(11, 31, 4), colSpec, orientation));
		builder.addLabel(Messages.getString("MEncoderVideo.24"), FormLayoutUtil.flip(cc.xy(1, 33), colSpec, orientation));

		defaultfont = new JTextField(configuration.getMencoderFont());
		defaultfont.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderFont(defaultfont.getText());
			}
		});

		builder.add(defaultfont, FormLayoutUtil.flip(cc.xyw(3, 33, 8), colSpec, orientation));

		JButton fontselect = new JButton("...");
		fontselect.addActionListener(new class() ActionListener {
			override
			public void actionPerformed(ActionEvent e) {
				JFileChooser chooser = new JFileChooser();
				chooser.setFileFilter(new FontFileFilter());
				int returnVal = chooser.showDialog(cast(Component) e.getSource(), Messages.getString("MEncoderVideo.25"));
				if (returnVal == JFileChooser.APPROVE_OPTION) {
					defaultfont.setText(chooser.getSelectedFile().getAbsolutePath());
					configuration.setMencoderFont(chooser.getSelectedFile().getAbsolutePath());
				}
			}
		});

		builder.add(fontselect, FormLayoutUtil.flip(cc.xyw(11, 33, 2), colSpec, orientation));
		builder.addLabel(Messages.getString("MEncoderVideo.37"), FormLayoutUtil.flip(cc.xyw(1, 35, 3), colSpec, orientation));

		alternateSubFolder = new JTextField(configuration.getAlternateSubsFolder());
		alternateSubFolder.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setAlternateSubsFolder(alternateSubFolder.getText());
			}
		});

		builder.add(alternateSubFolder, FormLayoutUtil.flip(cc.xyw(3, 35, 8), colSpec, orientation));

		JButton select = new JButton("...");
		select.addActionListener(new class() ActionListener {
			override
			public void actionPerformed(ActionEvent e) {
				JFileChooser chooser = null;
				try {
					chooser = new JFileChooser();
				} catch (Exception ee) {
					chooser = new JFileChooser(new RestrictedFileSystemView());
				}
				chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
				int returnVal = chooser.showDialog(cast(Component) e.getSource(), Messages.getString("FoldTab.28"));
				if (returnVal == JFileChooser.APPROVE_OPTION) {
					alternateSubFolder.setText(chooser.getSelectedFile().getAbsolutePath());
					configuration.setAlternateSubsFolder(chooser.getSelectedFile().getAbsolutePath());
				}
			}
		});

		builder.add(select, FormLayoutUtil.flip(cc.xyw(11, 35, 2), colSpec, orientation));
		builder.addLabel(Messages.getString("MEncoderVideo.12"), FormLayoutUtil.flip(cc.xy(1, 39, CellConstraints.RIGHT, CellConstraints.CENTER), colSpec, orientation));

		mencoder_ass_scale = new JTextField(configuration.getMencoderAssScale());
		mencoder_ass_scale.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderAssScale(mencoder_ass_scale.getText());
			}
		});

		builder.addLabel(Messages.getString("MEncoderVideo.13"), FormLayoutUtil.flip(cc.xy(5, 39), colSpec, orientation));

		mencoder_ass_outline = new JTextField(configuration.getMencoderAssOutline());
		mencoder_ass_outline.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderAssOutline(mencoder_ass_outline.getText());
			}
		});

		builder.addLabel(Messages.getString("MEncoderVideo.14"), FormLayoutUtil.flip(cc.xy(9, 39), colSpec, orientation));

		mencoder_ass_shadow = new JTextField(configuration.getMencoderAssShadow());
		mencoder_ass_shadow.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderAssShadow(mencoder_ass_shadow.getText());
			}
		});

		builder.addLabel(Messages.getString("MEncoderVideo.15"), FormLayoutUtil.flip(cc.xy(13, 39), colSpec, orientation));

		mencoder_ass_margin = new JTextField(configuration.getMencoderAssMargin());
		mencoder_ass_margin.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderAssMargin(mencoder_ass_margin.getText());
			}
		});

		builder.add(mencoder_ass_scale, FormLayoutUtil.flip(cc.xy(3, 39), colSpec, orientation));
		builder.add(mencoder_ass_outline, FormLayoutUtil.flip(cc.xy(7, 39), colSpec, orientation));
		builder.add(mencoder_ass_shadow, FormLayoutUtil.flip(cc.xy(11, 39), colSpec, orientation));
		builder.add(mencoder_ass_margin, FormLayoutUtil.flip(cc.xy(15, 39), colSpec, orientation));
		builder.addLabel(Messages.getString("MEncoderVideo.16"), FormLayoutUtil.flip(cc.xy(1, 41, CellConstraints.RIGHT, CellConstraints.CENTER), colSpec, orientation));

		mencoder_noass_scale = new JTextField(configuration.getMencoderNoAssScale());
		mencoder_noass_scale.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderNoAssScale(mencoder_noass_scale.getText());
			}
		});

		builder.addLabel(Messages.getString("MEncoderVideo.17"), FormLayoutUtil.flip(cc.xy(5, 41), colSpec, orientation));

		mencoder_noass_outline = new JTextField(configuration.getMencoderNoAssOutline());
		mencoder_noass_outline.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderNoAssOutline(mencoder_noass_outline.getText());
			}
		});

		builder.addLabel(Messages.getString("MEncoderVideo.18"), FormLayoutUtil.flip(cc.xy(9, 41), colSpec, orientation));

		mencoder_noass_blur = new JTextField(configuration.getMencoderNoAssBlur());
		mencoder_noass_blur.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderNoAssBlur(mencoder_noass_blur.getText());
			}
		});

		builder.addLabel(Messages.getString("MEncoderVideo.19"), FormLayoutUtil.flip(cc.xy(13, 41), colSpec, orientation));

		mencoder_noass_subpos = new JTextField(configuration.getMencoderNoAssSubPos());
		mencoder_noass_subpos.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderNoAssSubPos(mencoder_noass_subpos.getText());
			}
		});

		builder.add(mencoder_noass_scale, FormLayoutUtil.flip(cc.xy(3, 41), colSpec, orientation));
		builder.add(mencoder_noass_outline, FormLayoutUtil.flip(cc.xy(7, 41), colSpec, orientation));
		builder.add(mencoder_noass_blur, FormLayoutUtil.flip(cc.xy(11, 41), colSpec, orientation));
		builder.add(mencoder_noass_subpos, FormLayoutUtil.flip(cc.xy(15, 41), colSpec, orientation));

		ass = new JCheckBox(Messages.getString("MEncoderVideo.20"));
		ass.setContentAreaFilled(false);
		ass.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				if (e !is null) {
					configuration.setMencoderAss(e.getStateChange() == ItemEvent.SELECTED);
				}
			}
		});

		builder.add(ass, FormLayoutUtil.flip(cc.xy(1, 37), colSpec, orientation));
		ass.setSelected(configuration.isMencoderAss());
		ass.getItemListeners()[0].itemStateChanged(null);

		fc = new JCheckBox(Messages.getString("MEncoderVideo.21"));
		fc.setContentAreaFilled(false);
		fc.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				configuration.setMencoderFontConfig(e.getStateChange() == ItemEvent.SELECTED);
			}
		});

		builder.add(fc, FormLayoutUtil.flip(cc.xyw(3, 37, 5), colSpec, orientation));
		fc.setSelected(configuration.isMencoderFontConfig());

		assdefaultstyle = new JCheckBox(Messages.getString("MEncoderVideo.36"));
		assdefaultstyle.setContentAreaFilled(false);
		assdefaultstyle.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				configuration.setMencoderAssDefaultStyle(e.getStateChange() == ItemEvent.SELECTED);
			}
		});

		builder.add(assdefaultstyle, FormLayoutUtil.flip(cc.xyw(8, 37, 4), colSpec, orientation));
		assdefaultstyle.setSelected(configuration.isMencoderAssDefaultStyle());

		subs = new JCheckBox(Messages.getString("MEncoderVideo.22"));
		subs.setContentAreaFilled(false);

		if (configuration.isAutoloadSubtitles()) {
			subs.setSelected(true);
		}

		subs.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				configuration.setAutoloadSubtitles((e.getStateChange() == ItemEvent.SELECTED));
			}
		});

		builder.add(subs, FormLayoutUtil.flip(cc.xyw(1, 43, 15), colSpec, orientation));
		builder.addLabel(Messages.getString("MEncoderVideo.92"), FormLayoutUtil.flip(cc.xy(1, 45), colSpec, orientation));

		subq = new JTextField(configuration.getMencoderVobsubSubtitleQuality());
		subq.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderVobsubSubtitleQuality(subq.getText());
			}
		});

		builder.add(subq, FormLayoutUtil.flip(cc.xyw(3, 45, 1), colSpec, orientation));
		builder.addLabel(Messages.getString("MEncoderVideo.93"), FormLayoutUtil.flip(cc.xyw(1, 47, 6), colSpec, orientation));
		builder.addLabel(Messages.getString("MEncoderVideo.28") + "% ", FormLayoutUtil.flip(cc.xy(1, 49, CellConstraints.RIGHT, CellConstraints.CENTER), colSpec, orientation));

		ocw = new JTextField(configuration.getMencoderOverscanCompensationWidth());
		ocw.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderOverscanCompensationWidth(ocw.getText());
			}
		});

		builder.add(ocw, FormLayoutUtil.flip(cc.xyw(3, 49, 1), colSpec, orientation));
		builder.addLabel(Messages.getString("MEncoderVideo.30") ~ "% ", FormLayoutUtil.flip(cc.xy(5, 49), colSpec, orientation));

		och = new JTextField(configuration.getMencoderOverscanCompensationHeight());
		och.addKeyListener(new class() KeyListener {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				configuration.setMencoderOverscanCompensationHeight(och.getText());
			}
		});

		builder.add(och, FormLayoutUtil.flip(cc.xyw(7, 49, 1), colSpec, orientation));

		subColor = new JButton();
		subColor.setText(Messages.getString("MEncoderVideo.31"));
		subColor.setBackground(new Color(configuration.getSubsColor()));
		subColor.addActionListener(new class() ActionListener {
			override
			public void actionPerformed(ActionEvent e) {
				Color newColor = JColorChooser.showDialog(
						SwingUtilities.getWindowAncestor(cast(Component) PMS.get().getFrame()),
					Messages.getString("MEncoderVideo.125"),
					subColor.getBackground()
				);

				if (newColor !is null) {
					subColor.setBackground(newColor);
					configuration.setSubsColor(newColor.getRGB());
				}
			}
		});

		builder.add(subColor, FormLayoutUtil.flip(cc.xyw(12, 37, 4), colSpec, orientation));

		JCheckBox disableSubs = (cast(LooksFrame) PMS.get().getFrame()).getTr().getDisableSubs();
		disableSubs.addItemListener(new class() ItemListener {
			public void itemStateChanged(ItemEvent e) {
				configuration.setMencoderDisableSubs(e.getStateChange() == ItemEvent.SELECTED);

				subs.setEnabled(!configuration.isMencoderDisableSubs());
				subq.setEnabled(!configuration.isMencoderDisableSubs());
				defaultsubs.setEnabled(!configuration.isMencoderDisableSubs());
				subcp.setEnabled(!configuration.isMencoderDisableSubs());
				ass.setEnabled(!configuration.isMencoderDisableSubs());
				assdefaultstyle.setEnabled(!configuration.isMencoderDisableSubs());
				fribidi.setEnabled(!configuration.isMencoderDisableSubs());
				fc.setEnabled(!configuration.isMencoderDisableSubs());
				mencoder_ass_scale.setEnabled(!configuration.isMencoderDisableSubs());
				mencoder_ass_outline.setEnabled(!configuration.isMencoderDisableSubs());
				mencoder_ass_shadow.setEnabled(!configuration.isMencoderDisableSubs());
				mencoder_ass_margin.setEnabled(!configuration.isMencoderDisableSubs());
				mencoder_noass_scale.setEnabled(!configuration.isMencoderDisableSubs());
				mencoder_noass_outline.setEnabled(!configuration.isMencoderDisableSubs());
				mencoder_noass_blur.setEnabled(!configuration.isMencoderDisableSubs());
				mencoder_noass_subpos.setEnabled(!configuration.isMencoderDisableSubs());

				if (!configuration.isMencoderDisableSubs()) {
					ass.getItemListeners()[0].itemStateChanged(null);
				}
			}
		});

		if (configuration.isMencoderDisableSubs()) {
			disableSubs.setSelected(true);
		}

		JPanel panel = builder.getPanel();

		// Apply the orientation to the panel and all components in it
		panel.applyComponentOrientation(orientation);

		return panel;
	}

	override
	public int purpose() {
		return VIDEO_SIMPLEFILE_PLAYER;
	}

	override
	public String id() {
		return ID;
	}

	override
	public bool avisynth() {
		return false;
	}

	override
	public bool isTimeSeekable() {
		return true;
	}

	protected String[] getDefaultArgs() {
		List/*<String>*/ defaultArgsList = new ArrayList/*<String>*/();

		defaultArgsList.add("-msglevel");
		defaultArgsList.add("statusline=2");

		defaultArgsList.add("-oac");
		defaultArgsList.add((ac3Remux || dtsRemux) ? "copy" : (pcm ? "pcm" : "lavc"));

		defaultArgsList.add("-of");
		defaultArgsList.add((wmv || mpegts) ? "lavf" : ((pcm && avisynth()) ? "avi" : ((pcm || dtsRemux) ? "rawvideo" : "mpeg")));

		if (wmv) {
			defaultArgsList.add("-lavfopts");
			defaultArgsList.add("format=asf");
		} else if (mpegts) {
			defaultArgsList.add("-lavfopts");
			defaultArgsList.add("format=mpegts");
		}

		defaultArgsList.add("-mpegopts");
		defaultArgsList.add("format=mpeg2:muxrate=500000:vbuf_size=1194:abuf_size=64");


		defaultArgsList.add("-ovc");
		defaultArgsList.add(ovccopy ? "copy" : "lavc");

		String[] defaultArgsArray = new String[defaultArgsList.size()];
		defaultArgsList.toArray(defaultArgsArray);

		return defaultArgsArray;
	}

	private String[] sanitizeArgs(String[] args) {
		List/*<String>*/ sanitized = new ArrayList/*<String>*/();
		int i = 0;

		while (i < args.length) {
			String name = args[i];
			String value = null;

			foreach (String option ; INVALID_CUSTOM_OPTIONS) {
				if (option.opEquals(name)) {
					if ((i + 1) < args.length) {
					   value = " " ~ args[i + 1];
					   ++i;
					} else {
					   value = "";
					}

					LOGGER.warn(
						"Ignoring custom MEncoder option: %s%s; the following options cannot be changed: " ~ INVALID_CUSTOM_OPTIONS_LIST,
						name,
						value
					);

					break;
				}
			}

			if (value is null) {
				sanitized.add(args[i]);
			}

			++i;
		}

		return sanitized.toArray(new String[sanitized.size()]);
	}

	override
	public String[] args() {
		String args[] = null;
		String defaultArgs[] = getDefaultArgs();

		if (overriddenMainArgs !is null) {
			// add the sanitized custom MEncoder options.
			// not cached because they may be changed on the fly in the GUI
			// TODO if/when we upgrade to org.apache.commons.lang3:
			// args = ArrayUtils.addAll(defaultArgs, sanitizeArgs(overriddenMainArgs))
			String[] sanitizedCustomArgs = sanitizeArgs(overriddenMainArgs);
			args = new String[defaultArgs.length + sanitizedCustomArgs.length];
			System.arraycopy(defaultArgs, 0, args, 0, defaultArgs.length);
			System.arraycopy(sanitizedCustomArgs, 0, args, defaultArgs.length, sanitizedCustomArgs.length);
		} else {
			args = defaultArgs;
		}

		return args;
	}

	override
	public String executable() {
		return configuration.getMencoderPath();
	}

	private int[] getVideoBitrateConfig(String bitrate) {
		int bitrates[] = new int[2];

		if (bitrate.contains("(") && bitrate.contains(")")) {
			bitrates[1] = Integer.parseInt(bitrate.substring(bitrate.indexOf("(") + 1, bitrate.indexOf(")")));
		}

		if (bitrate.contains("(")) {
			bitrate = bitrate.substring(0, bitrate.indexOf("(")).trim();
		}

		if (isBlank(bitrate)) {
			bitrate = "0";
		}

		bitrates[0] = cast(int) Double.parseDouble(bitrate);

		return bitrates;
	}

	/**
	 * Note: This is not exact. The bitrate can go above this but it is generally pretty good.
	 * @return The maximum bitrate the video should be along with the buffer size using MEncoder vars
	 */
	private String addMaximumBitrateConstraints(String encodeSettings, DLNAMediaInfo media, String quality, RendererConfiguration mediaRenderer, String audioType) {
		int defaultMaxBitrates[] = getVideoBitrateConfig(configuration.getMaximumBitrate());
		int rendererMaxBitrates[] = new int[2];

		if (mediaRenderer.getMaxVideoBitrate() !is null) {
			rendererMaxBitrates = getVideoBitrateConfig(mediaRenderer.getMaxVideoBitrate());
		}

		if ((rendererMaxBitrates[0] > 0) && ((defaultMaxBitrates[0] == 0) || (rendererMaxBitrates[0] < defaultMaxBitrates[0]))) {
			defaultMaxBitrates = rendererMaxBitrates;
		}

		if (mediaRenderer.getCBRVideoBitrate() == 0 && defaultMaxBitrates[0] > 0 && !quality.contains("vrc_buf_size") && !quality.contains("vrc_maxrate") && !quality.contains("vbitrate")) {
			// Convert value from Mb to Kb
			defaultMaxBitrates[0] = 1000 * defaultMaxBitrates[0];

			// Half it since it seems to send up to 1 second of video in advance
			defaultMaxBitrates[0] = defaultMaxBitrates[0] / 2;

			int bufSize = 1835;
			if (media.isHDVideo()) {
				bufSize = defaultMaxBitrates[0] / 3;
			}

			if (bufSize > 7000) {
				bufSize = 7000;
			}

			if (defaultMaxBitrates[1] > 0) {
				bufSize = defaultMaxBitrates[1];
			}

			if (mediaRenderer.isDefaultVBVSize() && rendererMaxBitrates[1] == 0) {
				bufSize = 1835;
			}

			// Make room for audio
			// If audio is PCM, subtract 4600kb/s
			if ("pcm".opEquals(audioType)) {
				defaultMaxBitrates[0] = defaultMaxBitrates[0] - 4600;
			}
			// If audio is DTS, subtract 1510kb/s
			else if ("dts".opEquals(audioType)) {
				defaultMaxBitrates[0] = defaultMaxBitrates[0] - 1510;
			}
			// If audio is AC3, subtract 640kb/s to be safe
			else if ("ac3".opEquals(audioType)) {
				defaultMaxBitrates[0] = defaultMaxBitrates[0] - 640;
			}

			// Round down to the nearest Mb
			defaultMaxBitrates[0] = defaultMaxBitrates[0] / 1000 * 1000;

			encodeSettings += ":vrc_maxrate=" ~ defaultMaxBitrates[0] ~ ":vrc_buf_size=" ~ bufSize.toString();
		}

		return encodeSettings;
	}

	/*
	 * collapse the multiple internal ways of saying "subtitles are disabled" into a single method
	 * which returns true if any of the following are true:
	 *
	 *     1) configuration.isMencoderDisableSubs()
	 *     2) params.sid is null
	 *     3) avisynth()
	 */
	private bool isDisableSubtitles(OutputParams params) {
		return configuration.isMencoderDisableSubs() || (params.sid is null) || avisynth();
	}

	override
	public ProcessWrapper launchTranscode(
		String fileName,
		DLNAResource dlna,
		DLNAMediaInfo media,
		OutputParams params
	) {
		params.manageFastStart();

		bool avisynth = avisynth();

		setAudioAndSubs(fileName, media, params, configuration);
		String externalSubtitlesFileName = null;

		if (params.sid !is null && params.sid.isExternal()) {
			if (params.sid.isExternalFileUtf16()) {
				// convert UTF-16 -> UTF-8
				File convertedSubtitles = new File(PMS.getConfiguration().getTempFolder(), "utf8_" ~ params.sid.getExternalFile().getName());
				FileUtil.convertFileFromUtf16ToUtf8(params.sid.getExternalFile(), convertedSubtitles);
				externalSubtitlesFileName = ProcessUtil.getShortFileNameIfWideChars(convertedSubtitles.getAbsolutePath());
			} else {
				externalSubtitlesFileName = ProcessUtil.getShortFileNameIfWideChars(params.sid.getExternalFile().getAbsolutePath());
			}
		}

		InputFile newInput = new InputFile();
		newInput.setFilename(fileName);
		newInput.setPush(params.stdin);

		dvd = false;

		if (media !is null && media.getDvdtrack() > 0) {
			dvd = true;
		}

		ovccopy = false;
		pcm = false;
		ac3Remux = false;
		dtsRemux = false;
		wmv = false;

		int intOCW = 0;
		int intOCH = 0;

		try {
			intOCW = Integer.parseInt(configuration.getMencoderOverscanCompensationWidth());
		} catch (NumberFormatException e) {
			LOGGER.error("Cannot parse configured MEncoder overscan compensation width: \"%s\"", configuration.getMencoderOverscanCompensationWidth());
		}

		try {
			intOCH = Integer.parseInt(configuration.getMencoderOverscanCompensationHeight());
		} catch (NumberFormatException e) {
			LOGGER.error("Cannot parse configured MEncoder overscan compensation height: \"%s\"", configuration.getMencoderOverscanCompensationHeight());
		}

		if (params.sid is null && dvd && configuration.isMencoderRemuxMPEG2() && params.mediaRenderer.isMpeg2Supported()) {
			String expertOptions[] = getSpecificCodecOptions(
				configuration.getCodecSpecificConfig(),
				media,
				params,
				fileName,
				externalSubtitlesFileName,
				configuration.isMencoderIntelligentSync(),
				false
			);

			bool nomux = false;

			foreach (String s ; expertOptions) {
				if (s.opEquals("-nomux")) {
					nomux = true;
				}
			}

			if (!nomux) {
				ovccopy = true;
			}
		}

		String vcodec = "mpeg2video";

		if (params.mediaRenderer.isTranscodeToWMV()) {
			wmv = true;
			vcodec = "wmv2"; // http://wiki.megaframe.org/wiki/Ubuntu_XBOX_360#MEncoder not usable in streaming
		}

		mpegts = params.mediaRenderer.isTranscodeToMPEGTSAC3();

        // disable AC3 remux for stereo tracks with 384 kbits bitrate and PS3 renderer (PS3 FW bug?)
		bool ps3_and_stereo_and_384_kbits = params.aid !is null
			&& (params.mediaRenderer.isPS3() && params.aid.getAudioProperties().getNumberOfChannels() == 2)
			&& (params.aid.getBitRate() > 370000 && params.aid.getBitRate() < 400000);

		immutable bool isTSMuxerVideoEngineEnabled = PMS.getConfiguration().getEnginesAsList(PMS.get().getRegistry()).contains(TSMuxerVideo.ID);
		immutable bool mencoderAC3RemuxAudioDelayBug = (params.aid !is null) && (params.aid.getAudioProperties().getAudioDelay() != 0) && (params.timeseek == 0);
        if (!mencoderAC3RemuxAudioDelayBug && configuration.isRemuxAC3() && params.aid !is null && params.aid.isAC3() && !ps3_and_stereo_and_384_kbits && !avisynth() && params.mediaRenderer.isTranscodeToAC3()) {
			// AC3 remux takes priority
			ac3Remux = true;
		} else {
			// now check for DTS remux and LPCM streaming
			dtsRemux = isTSMuxerVideoEngineEnabled && configuration.isDTSEmbedInPCM() &&
				(
					!dvd ||
					configuration.isMencoderRemuxMPEG2()
				) && params.aid !is null &&
				params.aid.isDTS() &&
				!avisynth() &&
				params.mediaRenderer.isDTSPlayable();
			pcm = isTSMuxerVideoEngineEnabled && configuration.isMencoderUsePcm() &&
				(
					!dvd ||
					configuration.isMencoderRemuxMPEG2()
				)
				// disable LPCM transcoding for MP4 container with non-H264 video as workaround for mencoder's A/V sync bug
				&& !(media.getContainer().opEquals("mp4") && !media.getCodecV().opEquals("h264"))
				&& params.aid !is null &&
				(
					(params.aid.isDTS() && params.aid.getAudioProperties().getNumberOfChannels() <= 6) || // disable 7.1 DTS-HD => LPCM because of channels mapping bug
					params.aid.isLossless() ||
					params.aid.isTrueHD() ||
					(
						!configuration.isMencoderUsePcmForHQAudioOnly() &&
						(
							params.aid.isAC3() ||
							params.aid.isMP3() ||
							params.aid.isAAC() ||
							params.aid.isVorbis() ||
							// disable WMA to LPCM transcoding because of mencoder's channel mapping bug
							// (see CodecUtil.getMixerOutput)
							// params.aid.isWMA() ||
							params.aid.isMpegAudio()
						)
					)
				) && params.mediaRenderer.isLPCMPlayable();
		}

		if (dtsRemux || pcm) {
			params.losslessaudio = true;
			params.forceFps = media.getValidFps(false);
		}

		// mpeg2 remux still buggy with mencoder :\
		// TODO when we can still use it?
		ovccopy = false;

		if (pcm && avisynth()) {
			params.avidemux = true;
		}

		int channels;
		if (ac3Remux) {
			channels = params.aid.getAudioProperties().getNumberOfChannels(); // ac3 remux
		} else if (dtsRemux || wmv) {
			channels = 2;
		} else if (pcm) {
			channels = params.aid.getAudioProperties().getNumberOfChannels();
		} else {
			channels = configuration.getAudioChannelCount(); // 5.1 max for ac3 encoding
		}

		LOGGER.trace("channels=" ~ channels);

		String add = "";
		String rendererMencoderOptions = params.mediaRenderer.getCustomMencoderOptions(); // default: empty string
		String globalMencoderOptions = configuration.getMencoderCustomOptions(); // default: empty string

		String combinedCustomOptions = defaultString(globalMencoderOptions)
			~ " "
			~ defaultString(rendererMencoderOptions);

		if (!combinedCustomOptions.contains("-lavdopts")) {
			add = " -lavdopts debug=0";
		}

		if (isNotBlank(rendererMencoderOptions)) {
			/*
			 * ignore the renderer's custom MEncoder options if a) we're streaming a DVD (i.e. via dvd://)
			 * or b) the renderer's MEncoder options contain overscan settings (those are handled
			 * separately)
			 */

			// XXX we should weed out the unused/unwanted settings and keep the rest
			// (see sanitizeArgs()) rather than ignoring the options entirely
			if (rendererMencoderOptions.contains("expand=") || dvd) {
				rendererMencoderOptions = null;
			}
		}

		StringTokenizer st = new StringTokenizer(
			"-channels " ~ channels
			~ (isNotBlank(globalMencoderOptions) ? " " ~ globalMencoderOptions : "")
			~ (isNotBlank(rendererMencoderOptions) ? " " ~ rendererMencoderOptions : "")
			~ add,
			" "
		);

		// XXX why does this field (which is used to populate the array returned by args(),
		// called below) store the renderer-specific (i.e. not global) MEncoder options?
		overriddenMainArgs = new String[st.countTokens()];

		{
			int nThreads = (dvd || fileName.toLowerCase().endsWith("dvr-ms")) ?
				1 :
				configuration.getMencoderMaxThreads();
			bool handleToken = false;
			int i = 0;

			while (st.hasMoreTokens()) {
				String token = st.nextToken().trim();

				if (handleToken) {
					token ~= ":threads=" ~ nThreads;

					if (configuration.getSkipLoopFilterEnabled() && !avisynth()) {
						token ~= ":skiploopfilter=all";
					}

					handleToken = false;
				}

				if (token.toLowerCase().contains("lavdopts")) {
					handleToken = true;
				}

				overriddenMainArgs[i++] = token;
			}
		}

		if (configuration.getMencoderMainSettings() !is null) {
			String mainConfig = configuration.getMencoderMainSettings();
			String customSettings = params.mediaRenderer.getCustomMencoderQualitySettings();

			// Custom settings in PMS may override the settings of the saved configuration
			if (isNotBlank(customSettings)) {
				mainConfig = customSettings;
			}

			if (mainConfig.contains("/*")) {
				mainConfig = mainConfig.substring(mainConfig.indexOf("/*"));
			}

			// Ditlew - WDTV Live (+ other byte asking clients), CBR. This probably ought to be placed in addMaximumBitrateConstraints(..)
			int cbr_bitrate = params.mediaRenderer.getCBRVideoBitrate();
			String cbr_settings = (cbr_bitrate > 0) ?
				":vrc_buf_size=5000:vrc_minrate=" ~ cbr_bitrate ~ ":vrc_maxrate=" ~ cbr_bitrate ~ ":vbitrate=" ~ ((cbr_bitrate > 16000) ? cbr_bitrate * 1000 : cbr_bitrate) :
				"";
			String encodeSettings = "-lavcopts autoaspect=1:vcodec=" ~ vcodec ~
				(wmv ? ":acodec=wmav2:abitrate=448" : (cbr_settings + ":acodec=" ~ (configuration.isMencoderAc3Fixed() ? "ac3_fixed" : "ac3") ~
				":abitrate=" ~ CodecUtil.getAC3Bitrate(configuration, params.aid))) ~
				":threads=" ~ (wmv ? 1 : configuration.getMencoderMaxThreads()) ~
				("".opEquals(mainConfig) ? "" : ":" ~ mainConfig);

			String audioType = "ac3";

			if (dtsRemux) {
				audioType = "dts";
			} else if (pcm) {
				audioType = "pcm";
			}

			encodeSettings = addMaximumBitrateConstraints(encodeSettings, media, mainConfig, params.mediaRenderer, audioType);
			st = new StringTokenizer(encodeSettings, " ");

			{
				int i = overriddenMainArgs.length; // old length
				overriddenMainArgs = Arrays.copyOf(overriddenMainArgs, overriddenMainArgs.length + st.countTokens());

				while (st.hasMoreTokens()) {
					overriddenMainArgs[i++] = st.nextToken();
				}
			}
		}

		bool foundNoassParam = false;

		if (media !is null) {
			String expertOptions [] = getSpecificCodecOptions(
				configuration.getCodecSpecificConfig(),
				media,
				params,
				fileName,
				externalSubtitlesFileName,
				configuration.isMencoderIntelligentSync(),
				false
			);

			foreach (String s ; expertOptions) {
				if (s.opEquals("-noass")) {
					foundNoassParam = true;
				}
			}
		}

		StringBuilder sb = new StringBuilder();
		// Set subtitles options
		if (!isDisableSubtitles(params)) {
			int subtitleMargin = 0;
			int userMargin     = 0;

			// Use ASS flag (and therefore ASS font styles) for all subtitled files except vobsub, PGS and dvd
			bool apply_ass_styling = params.sid.getType() != SubtitleType.VOBSUB &&
					params.sid.getType() != SubtitleType.PGS &&
					configuration.isMencoderAss() &&   // GUI: enable subtitles formating
					!foundNoassParam &&                // GUI: codec specific options
					!dvd;

			if (apply_ass_styling) {
				sb.append("-ass ");

				// GUI: Override ASS subtitles style if requested (always for SRT and TX3G subtitles)
				bool override_ass_style = !configuration.isMencoderAssDefaultStyle() ||
						params.sid.getType() == SubtitleType.SUBRIP ||
						params.sid.getType() == SubtitleType.TX3G;

				if (override_ass_style) {
					String assSubColor = "ffffff00";
					if (configuration.getSubsColor() != 0) {
						assSubColor = Integer.toHexString(configuration.getSubsColor());
						if (assSubColor.length() > 2) {
							assSubColor = assSubColor.substring(2) + "00";
						}
					}

					sb.append("-ass-color ").append(assSubColor).append(" -ass-border-color 00000000 -ass-font-scale ").append(configuration.getMencoderAssScale());

					// set subtitles font
					if (configuration.getMencoderFont() !is null && configuration.getMencoderFont().length() > 0) {
						// set font with -font option, workaround for
						// https://github.com/Happy-Neko/ps3mediaserver/commit/52e62203ea12c40628de1869882994ce1065446a#commitcomment-990156 bug
						sb.append(" -font ").append(configuration.getMencoderFont()).append(" ");
						sb.append(" -ass-force-style FontName=").append(configuration.getMencoderFont()).append(",");
					} else {
						String font = CodecUtil.getDefaultFontPath();
						if (isNotBlank(font)) {
							// Variable "font" contains a font path instead of a font name.
							// Does "-ass-force-style" support font paths? In tests on OS X
							// the font path is ignored (Outline, Shadow and MarginV are
							// used, though) and the "-font" definition is used instead.
							// See: https://github.com/ps3mediaserver/ps3mediaserver/pull/14
							sb.append(" -font ").append(font).append(" ");
							sb.append(" -ass-force-style FontName=").append(font).append(",");
						} else {
							sb.append(" -font Arial ");
							sb.append(" -ass-force-style FontName=Arial,");
						}
					}

					// Add to the subtitle margin if overscan compensation is being used
					// This keeps the subtitle text inside the frame instead of in the border
					if (intOCH > 0) {
						subtitleMargin = (media.getHeight() / 100) * intOCH;
					}

					sb.append("Outline=").append(configuration.getMencoderAssOutline()).append(",Shadow=").append(configuration.getMencoderAssShadow());

					try {
						userMargin = Integer.parseInt(configuration.getMencoderAssMargin());
					} catch (NumberFormatException n) {
						LOGGER._debug("Could not parse SSA margin from \"" ~ configuration.getMencoderAssMargin() ~ "\"");
					}

					subtitleMargin = subtitleMargin + userMargin;

					sb.append(",MarginV=").append(subtitleMargin).append(" ");
				} else if (intOCH > 0) {
					sb.append("-ass-force-style MarginV=").append(subtitleMargin).append(" ");
				}

				// MEncoder is not compiled with fontconfig on Mac OS X, therefore
				// use of the "-ass" option also requires the "-font" option.
				if (Platform.isMac() && sb.toString().indexOf(" -font ") < 0) {
					String font = CodecUtil.getDefaultFontPath();

					if (isNotBlank(font)) {
						sb.append("-font ").append(font).append(" ");
					}
				}

				// Workaround for MPlayer #2041, remove when that bug is fixed
				if (!params.sid.isEmbedded()) {
					sb.append("-noflip-hebrew ");
				}
			// use PLAINTEXT formating
			} else {
				// set subtitles font
				if (configuration.getMencoderFont() !is null && configuration.getMencoderFont().length() > 0) {
					sb.append(" -font ").append(configuration.getMencoderFont()).append(" ");
				} else {
					String font = CodecUtil.getDefaultFontPath();
					if (isNotBlank(font)) {
						sb.append(" -font ").append(font).append(" ");
					}
				}

				sb.append(" -subfont-text-scale ").append(configuration.getMencoderNoAssScale());
				sb.append(" -subfont-outline ").append(configuration.getMencoderNoAssOutline());
				sb.append(" -subfont-blur ").append(configuration.getMencoderNoAssBlur());

				// Add to the subtitle margin if overscan compensation is being used
				// This keeps the subtitle text inside the frame instead of in the border
				if (intOCH > 0) {
					subtitleMargin = intOCH;
				}

				try {
					userMargin = Integer.parseInt(configuration.getMencoderNoAssSubPos());
				} catch (NumberFormatException n) {
					LOGGER._debug("Could not parse subpos from \"" ~ configuration.getMencoderNoAssSubPos() ~ "\"");
				}

				subtitleMargin = subtitleMargin + userMargin;

				sb.append(" -subpos ").append(100 - subtitleMargin).append(" ");
			}

			// Common subtitle options

			// MEncoder on Mac OS X is compiled without fontconfig support.
			// Appending the flag will break execution, so skip it on Mac OS X.
			if (!Platform.isMac()) {
				// Use fontconfig if enabled
				sb.append("-").append(configuration.isMencoderFontConfig() ? "" : "no").append("fontconfig ");
			}
			// Apply DVD/VOBSUB subtitle quality
			if (params.sid.getType() == SubtitleType.VOBSUB && configuration.getMencoderVobsubSubtitleQuality() !is null) {
				String subtitleQuality = configuration.getMencoderVobsubSubtitleQuality();

				sb.append("-spuaa ").append(subtitleQuality).append(" ");
			}

			// external subtitles file
			if (params.sid.isExternal()) {
				if (!params.sid.isExternalFileUtf()) {
					String subcp = null;

					// append -subcp option for non UTF external subtitles
					if (isNotBlank(configuration.getMencoderSubCp())) {
						// manual setting
						subcp = configuration.getMencoderSubCp();
					} else if (isNotBlank(SubtitleUtils.getSubCpOptionForMencoder(params.sid))) {
						// autodetect charset (blank mencoder_subcp config option)
						subcp = SubtitleUtils.getSubCpOptionForMencoder(params.sid);
					}

					if (isNotBlank(subcp)) {
						sb.append("-subcp ").append(subcp).append(" ");
						if (configuration.isMencoderSubFribidi()) {
							sb.append("-fribidi-charset ").append(subcp).append(" ");
						}
					}
				}
			}
		}

		st = new StringTokenizer(sb.toString(), " ");

		{
			int i = overriddenMainArgs.length; // old length
			overriddenMainArgs = Arrays.copyOf(overriddenMainArgs, overriddenMainArgs.length + st.countTokens());
			bool handleToken = false;

			while (st.hasMoreTokens()) {
				String s = st.nextToken();

				if (handleToken) {
					s = "-quiet";
					handleToken = false;
				}

				if ((!configuration.isMencoderAss() || dvd) && s.contains("-ass")) {
					s = "-quiet";
					handleToken = true;
				}

				overriddenMainArgs[i++] = s;
			}
		}

		List/*<String>*/ cmdList = new ArrayList/*<String>*/();

		cmdList.add(executable());

		// timeseek
		// XXX -ss 0 is is included for parity with the old (cmdArray) code: it may be possible to omit it
		cmdList.add("-ss");
		cmdList.add((params.timeseek > 0) ? "" ~ params.timeseek.toString() : "0");

		if (dvd) {
			cmdList.add("-dvd-device");
		}

		// input filename
		if (avisynth && !fileName.toLowerCase().endsWith(".iso")) {
			File avsFile = FFMpegAviSynthVideo.getAVSScript(fileName, params.sid, params.fromFrame, params.toFrame);
			cmdList.add(ProcessUtil.getShortFileNameIfWideChars(avsFile.getAbsolutePath()));
		} else {
			if (params.stdin !is null) {
				cmdList.add("-");
			} else {
				cmdList.add(fileName);
			}
		}

		if (dvd) {
			cmdList.add("dvd://" ~ media.getDvdtrack());
		}

		foreach (String arg ; args()) {
			if (arg.contains("format=mpeg2") && media.getAspect() !is null && media.getValidAspect(true) !is null) {
				cmdList.add(arg ~ ":vaspect=" ~ media.getValidAspect(true));
			} else {
				cmdList.add(arg);
			}
		}

		if (!dtsRemux && !pcm && !avisynth() && params.aid !is null && media.getAudioTracksList().size() > 1) {
			cmdList.add("-aid");
			bool lavf = false; // TODO Need to add support for LAVF demuxing
			cmdList.add("" ~ (lavf ? params.aid.getId() + 1 : params.aid.getId()).toString());
		}

		/*
		 * handle subtitles
		 *
		 * try to reconcile the fact that the handling of "Definitely disable subtitles" is spread out
		 * over net.pms.encoders.Player.setAudioAndSubs and here by setting both of MEncoder's "disable
		 * subs" options if any of the internal conditions for disabling subtitles are met.
		 */
		if (isDisableSubtitles(params)) {
			// MKV: in some circumstances, MEncoder automatically selects an internal sub unless we explicitly disable (internal) subtitles
			// http://www.ps3mediaserver.org/forum/viewtopic.php?f=14&t=15891
			cmdList.add("-nosub");
			// make sure external subs are not automatically loaded
			cmdList.add("-noautosub");
		} else {
			// note: isEmbedded() and isExternal() are mutually exclusive
			if (params.sid.isEmbedded()) { // internal (embedded) subs
				cmdList.add("-sid");
				cmdList.add(params.sid.getId().toString());
			} else { // external subtitles
				assert(params.sid.isExternal()); // confirm the mutual exclusion

				if (params.sid.getType() == SubtitleType.VOBSUB) {
					cmdList.add("-vobsub");
					cmdList.add(externalSubtitlesFileName.substring(0, externalSubtitlesFileName.length() - 4));
					cmdList.add("-slang");
					cmdList.add("" ~ params.sid.getLang());
				} else {
					cmdList.add("-sub");
					cmdList.add(externalSubtitlesFileName.replace(",", "\\,")); // Commas in MEncoder separate multiple subtitle files

					if (params.sid.isExternalFileUtf()) {
						// append -utf8 option for UTF-8 external subtitles
						cmdList.add("-utf8");
					}
				}
			}
		}

		// -ofps
		String validFramerate = (media !is null) ? media.getValidFps(true) : null; // optional input framerate: may be null
		String framerate = (validFramerate !is null) ? validFramerate : "24000/1001"; // where a framerate is required, use the input framerate or 24000/1001
		String ofps = framerate;

		// optional -fps or -mc
		if (configuration.isMencoderForceFps()) {
			if (!configuration.isFix25FPSAvMismatch()) {
				cmdList.add("-fps");
				cmdList.add(framerate);
			} else if (validFramerate !is null) { // XXX not sure why this "fix" requires the input to have a valid framerate, but that's the logic in the old (cmdArray) code
				cmdList.add("-mc");
				cmdList.add("0.005");
				ofps = "25";
			}
		}

		cmdList.add("-ofps");
		cmdList.add(ofps);

		if (fileName.toLowerCase().endsWith(".evo")) {
			cmdList.add("-psprobe");
			cmdList.add("10000");
		}

		bool deinterlace = configuration.isMencoderYadif();

		// Check if the media renderer supports this resolution
		bool isResolutionTooHighForRenderer = params.mediaRenderer.isVideoRescale()
			&& media !is null
			&& (
				(media.getWidth() > params.mediaRenderer.getMaxVideoWidth())
				||
				(media.getHeight() > params.mediaRenderer.getMaxVideoHeight())
			);

		// Video scaler and overscan compensation
		bool scaleBool = isResolutionTooHighForRenderer
			|| (configuration.isMencoderScaler() && (configuration.getMencoderScaleX() != 0 || configuration.getMencoderScaleY() != 0))
			|| (intOCW > 0 || intOCH > 0);

		if ((deinterlace || scaleBool) && !avisynth()) {
			StringBuilder vfValueOverscanPrepend = new StringBuilder();
			StringBuilder vfValueOverscanMiddle  = new StringBuilder();
			StringBuilder vfValueVS              = new StringBuilder();
			StringBuilder vfValueComplete        = new StringBuilder();

			String deinterlaceComma = "";
			int scaleWidth = 0;
			int scaleHeight = 0;
			double rendererAspectRatio;

			// Set defaults
			if (media !is null && media.getWidth() > 0 && media.getHeight() > 0) {
				scaleWidth = media.getWidth();
				scaleHeight = media.getHeight();
			}

			/*
			 * Implement overscan compensation settings
			 *
			 * This feature takes into account aspect ratio,
			 * making it less blunt than the Video Scaler option
			 */
			if (intOCW > 0 || intOCH > 0) {
				int intOCWPixels = (media.getWidth()  / 100) * intOCW;
				int intOCHPixels = (media.getHeight() / 100) * intOCH;

				scaleWidth  = scaleWidth  + intOCWPixels;
				scaleHeight = scaleHeight + intOCHPixels;

				// See if the video needs to be scaled down
				if (
					params.mediaRenderer.isVideoRescale() &&
					(
						(scaleWidth > params.mediaRenderer.getMaxVideoWidth()) ||
						(scaleHeight > params.mediaRenderer.getMaxVideoHeight())
					)
				) {
					double overscannedAspectRatio = scaleWidth / scaleHeight;
					rendererAspectRatio = params.mediaRenderer.getMaxVideoWidth() / params.mediaRenderer.getMaxVideoHeight();

					if (overscannedAspectRatio > rendererAspectRatio) {
						// Limit video by width
						scaleWidth  = params.mediaRenderer.getMaxVideoWidth();
						scaleHeight = cast(int) Math.round(params.mediaRenderer.getMaxVideoWidth() / overscannedAspectRatio);
					} else {
						// Limit video by height
						scaleWidth  = cast(int) Math.round(params.mediaRenderer.getMaxVideoHeight() * overscannedAspectRatio);
						scaleHeight = params.mediaRenderer.getMaxVideoHeight();
					}
				}

				vfValueOverscanPrepend.append("softskip,expand=-").append(intOCWPixels).append(":-").append(intOCHPixels);
				vfValueOverscanMiddle.append(",scale=").append(scaleWidth).append(":").append(scaleHeight);
			}

			/*
			 * Video Scaler and renderer-specific resolution-limiter
			 */
			if (configuration.isMencoderScaler()) {
				// Use the manual, user-controlled scaler
				if (configuration.getMencoderScaleX() != 0) {
					if (configuration.getMencoderScaleX() <= params.mediaRenderer.getMaxVideoWidth()) {
						scaleWidth = configuration.getMencoderScaleX();
					} else {
						scaleWidth = params.mediaRenderer.getMaxVideoWidth();
					}
				}

				if (configuration.getMencoderScaleY() != 0) {
					if (configuration.getMencoderScaleY() <= params.mediaRenderer.getMaxVideoHeight()) {
						scaleHeight = configuration.getMencoderScaleY();
					} else {
						scaleHeight = params.mediaRenderer.getMaxVideoHeight();
					}
				}

				LOGGER.info("Setting video resolution to: " ~ scaleWidth.toString() ~ "x" ~ scaleHeight.toString() ~ ", your Video Scaler setting");

				vfValueVS.append("scale=").append(scaleWidth).append(":").append(scaleHeight);

			/*
			 * The video resolution is too big for the renderer so we need to scale it down
			 */
			} else if (
				media !is null &&
				media.getWidth() > 0 &&
				media.getHeight() > 0 &&
				(
					media.getWidth()  > params.mediaRenderer.getMaxVideoWidth() ||
					media.getHeight() > params.mediaRenderer.getMaxVideoHeight()
				)
			) {
				double videoAspectRatio =cast (double) media.getWidth() / cast(double) media.getHeight();
				rendererAspectRatio = cast(double) params.mediaRenderer.getMaxVideoWidth() / cast(double) params.mediaRenderer.getMaxVideoHeight();

				/*
				 * First we deal with some exceptions, then if they are not matched we will
				 * let the renderer limits work.
				 *
				 * This is so, for example, we can still define a maximum resolution of
				 * 1920x1080 in the renderer config file but still support 1920x1088 when
				 * it's needed, otherwise we would either resize 1088 to 1080, meaning the
				 * ugly (unused) bottom 8 pixels would be displayed, or we would limit all
				 * videos to 1088 causing the bottom 8 meaningful pixels to be cut off.
				 */
				if (media.getWidth() == 3840 && media.getHeight() == 1080) {
					// Full-SBS
					scaleWidth  = 1920;
					scaleHeight = 1080;
				} else if (media.getWidth() == 1920 && media.getHeight() == 2160) {
					// Full-OU
					scaleWidth  = 1920;
					scaleHeight = 1080;
				} else if (media.getWidth() == 1920 && media.getHeight() == 1088) {
					// SAT capture
					scaleWidth  = 1920;
					scaleHeight = 1088;
				} else {
					// Passed the exceptions, now we allow the renderer to define the limits
					if (videoAspectRatio > rendererAspectRatio) {
						scaleWidth  = params.mediaRenderer.getMaxVideoWidth();
						scaleHeight = cast(int) Math.round(params.mediaRenderer.getMaxVideoWidth() / videoAspectRatio);
					} else {
						scaleWidth  = cast(int) Math.round(params.mediaRenderer.getMaxVideoHeight() * videoAspectRatio);
						scaleHeight = params.mediaRenderer.getMaxVideoHeight();
					}
				}

				LOGGER.info("Setting video resolution to: " ~ scaleWidth ~ "x" ~ scaleHeight ~ ", the maximum your renderer supports");

				vfValueVS.append("scale=").append(scaleWidth).append(":").append(scaleHeight);
			}

			// Put the string together taking into account overscan compensation and video scaler
			if (intOCW > 0 || intOCH > 0) {
				vfValueComplete.append(vfValueOverscanPrepend).append(vfValueOverscanMiddle).append(",harddup");
				LOGGER.info("Setting video resolution to: " ~ scaleWidth ~ "x" ~ scaleHeight ~ ", to fit your overscan compensation");
			} else {
				vfValueComplete.append(vfValueVS);
			}

			if (deinterlace) {
				deinterlaceComma = ",";
			}

			String vfValue = (deinterlace ? "yadif" : "") ~ (scaleBool ? deinterlaceComma ~ vfValueComplete : "");

			if (isNotBlank(vfValue)) {
				cmdList.add("-vf");
				cmdList.add(vfValue);
			}
		}

		/*
		 * The PS3 and possibly other renderers display videos incorrectly
		 * if the dimensions aren't divisible by 4, so if that is the
		 * case we scale it down to the nearest 4.
		 * This fixes the long-time bug of videos displaying in black and
		 * white with diagonal strips of colour, weird one.
		 *
		 * TODO: Integrate this with the other stuff so that "scale" only
		 * ever appears once in the MEncoder CMD.
		 */
		if (media !is null && (media.getWidth() % 4 != 0) || media.getHeight() % 4 != 0) {
			int newWidth;
			int newHeight;

			newWidth  = (media.getWidth() / 4) * 4;
			newHeight = (media.getHeight() / 4) * 4;

			cmdList.add("-vf");
			cmdList.add("softskip,scale=" ~ newWidth.toString() ~ ":" ~ newHeight.toString());
		}

		if (configuration.getMencoderMT() && !avisynth && !dvd && !(media.getCodecV() !is null && (media.getCodecV().opEquals("mpeg2video")))) {
			cmdList.add("-lavdopts");
			cmdList.add("fast");
		}

		bool disableMc0AndNoskip = false;

		// Process the options for this file in Transcoding Settings -> Mencoder -> Expert Settings: Codec-specific parameters
		// TODO this is better handled by a plugin with scripting support and will be removed
		if (media !is null) {
			String expertOptions[] = getSpecificCodecOptions(
				configuration.getCodecSpecificConfig(),
				media,
				params,
				fileName,
				externalSubtitlesFileName,
				configuration.isMencoderIntelligentSync(),
				false
			);

			// the parameters (expertOptions) are processed in 3 passes
			// 1) process expertOptions
			// 2) process cmdList
			// 3) append expertOptions to cmdList

			if (expertOptions !is null && expertOptions.length > 0) {
				// remove this option (key) from the cmdList in pass 2.
				// if the bool value is true, also remove the option's corresponding value
				Map/*<String, Boolean>*/ removeCmdListOption = new HashMap/*<String, Boolean>*/();

				// if this option (key) is defined in cmdList, merge this string value into the
				// option's value in pass 2. the value is a string format template into which the
				// cmdList option value is injected
				Map/*<String, String>*/ mergeCmdListOption = new HashMap/*<String, String>*/();

				// merges that are performed in pass 2 are logged in this map; the key (string) is
				// the option name and the value is a bool indicating whether the option was merged
				// or not. the map is populated after pass 1 with the options from mergeCmdListOption
				// and all values initialised to false. if an option was merged, it is not appended
				// to cmdList
				Map/*<String, Boolean>*/ mergedCmdListOption = new HashMap/*<String, Boolean>*/();

				// pass 1: process expertOptions
				for (int i = 0; i < expertOptions.length; ++i) {
					if (expertOptions[i].opEquals("-noass")) {
						// remove -ass from cmdList in pass 2.
						// -ass won't have been added in this method (getSpecificCodecOptions
						// has been called multiple times above to check for -noass and -nomux)
						// but it may have been added via the renderer or global MEncoder options.
						// XXX: there are currently 10 other -ass options (-ass-color, -ass-border-color &c.).
						// technically, they should all be removed...
						removeCmdListOption.put("-ass", false); // false: option does not have a corresponding value
						// remove -noass from expertOptions in pass 3
						expertOptions[i] = REMOVE_OPTION;
					} else if (expertOptions[i].opEquals("-nomux")) {
						expertOptions[i] = REMOVE_OPTION;
					} else if (expertOptions[i].opEquals("-mt")) {
						// not an MEncoder option so remove it from exportOptions.
						// multi-threaded MEncoder is used by default, so this is obsolete (TODO: Remove it from the description)
						expertOptions[i] = REMOVE_OPTION;
					} else if (expertOptions[i].opEquals("-ofps")) {
						// replace the cmdList version with the expertOptions version i.e. remove the former
						removeCmdListOption.put("-ofps", true);
						// skip (i.e. leave unchanged) the exportOptions value
						++i;
					} else if (expertOptions[i].opEquals("-fps")) {
						removeCmdListOption.put("-fps", true);
						++i;
					} else if (expertOptions[i].opEquals("-ovc")) {
						removeCmdListOption.put("-ovc", true);
						++i;
					} else if (expertOptions[i].opEquals("-channels")) {
						removeCmdListOption.put("-channels", true);
						++i;
					} else if (expertOptions[i].opEquals("-oac")) {
						removeCmdListOption.put("-oac", true);
						++i;
					} else if (expertOptions[i].opEquals("-quality")) {
						// XXX like the old (cmdArray) code, this clobbers the old -lavcopts value
						String lavcopts = String.format(
							"autoaspect=1:vcodec=%s:acodec=%s:abitrate=%s:threads=%d:%s",
							vcodec,
							(configuration.isMencoderAc3Fixed() ? "ac3_fixed" : "ac3"),
							CodecUtil.getAC3Bitrate(configuration, params.aid),
							configuration.getMencoderMaxThreads(),
							expertOptions[i + 1]
						);

						// append bitrate-limiting options if configured
						lavcopts = addMaximumBitrateConstraints(
							lavcopts,
							media,
							lavcopts,
							params.mediaRenderer,
							""
						);

						// a string format with no placeholders, so the cmdList option value is ignored.
						// note: we protect "%" from being interpreted as a format by converting it to "%%",
						// which is then turned back into "%" when the format is processed
						mergeCmdListOption.put("-lavcopts", lavcopts.replace("%", "%%"));
						// remove -quality <value>
						expertOptions[i] = expertOptions[i + 1] = REMOVE_OPTION;
						++i;
					} else if (expertOptions[i].opEquals("-mpegopts")) {
						mergeCmdListOption.put("-mpegopts", "%s:" + expertOptions[i + 1].replace("%", "%%"));
						// merge if cmdList already contains -mpegopts, but don't append if it doesn't (parity with the old (cmdArray) version)
						expertOptions[i] = expertOptions[i + 1] = REMOVE_OPTION;
						++i;
					} else if (expertOptions[i].opEquals("-vf")) {
						mergeCmdListOption.put("-vf", "%s," + expertOptions[i + 1].replace("%", "%%"));
						++i;
					} else if (expertOptions[i].opEquals("-af")) {
						mergeCmdListOption.put("-af", "%s," + expertOptions[i + 1].replace("%", "%%"));
						++i;
					} else if (expertOptions[i].opEquals("-nosync")) {
						disableMc0AndNoskip = true;
						expertOptions[i] = REMOVE_OPTION;
					} else if (expertOptions[i].opEquals("-mc")) {
						disableMc0AndNoskip = true;
					}
				}

				foreach (String key ; mergeCmdListOption.keySet()) {
					mergedCmdListOption.put(key, false);
				}

				// pass 2: process cmdList
				List/*<String>*/ transformedCmdList = new ArrayList/*<String>*/();

				for (int i = 0; i < cmdList.size(); ++i) {
					String option = cmdList.get(i);

					// we remove an option by *not* adding it to transformedCmdList
					if (removeCmdListOption.containsKey(option)) {
						if (isTrue(removeCmdListOption.get(option))) { // true: remove (i.e. don't add) the corresponding value
							++i;
						}
					} else {
						transformedCmdList.add(option);

						if (mergeCmdListOption.containsKey(option)) {
							String format = mergeCmdListOption.get(option);
							String value = String.format(format, cmdList.get(i + 1));
							// record the fact that an expertOption value has been merged into this cmdList value
							mergedCmdListOption.put(option, true);
							transformedCmdList.add(value);
							++i;
						}
					}
				}

				cmdList = transformedCmdList;

				// pass 3: append expertOptions to cmdList
				for (int i = 0; i < expertOptions.length; ++i) {
					String option = expertOptions[i];

					if (option != REMOVE_OPTION) {
						if (isTrue(mergedCmdListOption.get(option))) { // true: this option and its value have already been merged into existing cmdList options
							++i; // skip the value
						} else {
							cmdList.add(option);
						}
					}
				}
			}
		}

		if ((pcm || dtsRemux || ac3Remux) || (configuration.isMencoderNoOutOfSync() && !disableMc0AndNoskip)) {
			if (configuration.isFix25FPSAvMismatch()) {
				cmdList.add("-mc");
				cmdList.add("0.005");
			} else {
				cmdList.add("-mc");
				cmdList.add("0");
				cmdList.add("-noskip");
			}
		}

		if (params.timeend > 0) {
			cmdList.add("-endpos");
			cmdList.add("" + params.timeend);
		}

		String rate = "48000";
		if (params.mediaRenderer.isXBOX()) {
			rate = "44100";
		}

		// force srate -> cause ac3's mencoder doesn't like anything other than 48khz
		if (media !is null && !pcm && !dtsRemux && !ac3Remux) {
			cmdList.add("-af");
			cmdList.add("lavcresample=" + rate);
			cmdList.add("-srate");
			cmdList.add(rate);
		}

		// add a -cache option for piped media (e.g. rar/zip file entries):
		// https://code.google.com/p/ps3mediaserver/issues/detail?id=911
		if (params.stdin !is null) {
			cmdList.add("-cache");
			cmdList.add("8192");
		}

		PipeProcess pipe = null;

		ProcessWrapperImpl pw = null;

		if (pcm || dtsRemux) {
			// transcode video, demux audio, remux with tsmuxer
			bool channels_filter_present = false;

			foreach (String s ; cmdList) {
				if (isNotBlank(s) && s.startsWith("channels")) {
					channels_filter_present = true;
					break;
				}
			}

			if (params.avidemux) {
				pipe = new PipeProcess("mencoder" ~ System.currentTimeMillis().toString(), (pcm || dtsRemux || ac3Remux) ? null : params);
				params.input_pipes[0] = pipe;

				cmdList.add("-o");
				cmdList.add(pipe.getInputPipe());

				if (pcm && !channels_filter_present && params.aid !is null) {
					String mixer = getLPCMChannelMappingForMencoder(params.aid);
					if (isNotBlank(mixer)) {
						cmdList.add("-af");
						cmdList.add(mixer);
					}
				}

				String[] cmdArray = new String[cmdList.size()];
				cmdList.toArray(cmdArray);
				pw = new ProcessWrapperImpl(cmdArray, params);

				PipeProcess videoPipe = new PipeProcess("videoPipe" ~ System.currentTimeMillis().toString(), "out", "reconnect");
				PipeProcess audioPipe = new PipeProcess("audioPipe" ~ System.currentTimeMillis().toString(), "out", "reconnect");

				ProcessWrapper videoPipeProcess = videoPipe.getPipeProcess();
				ProcessWrapper audioPipeProcess = audioPipe.getPipeProcess();

				params.output_pipes[0] = videoPipe;
				params.output_pipes[1] = audioPipe;

				pw.attachProcess(videoPipeProcess);
				pw.attachProcess(audioPipeProcess);
				videoPipeProcess.runInNewThread();
				audioPipeProcess.runInNewThread();
				try {
					Thread.sleep(50);
				} catch (InterruptedException e) { }
				videoPipe.deleteLater();
				audioPipe.deleteLater();
			} else {
				// remove the -oac switch, otherwise the "too many video packets" errors appear again
				for (ListIterator/*<String>*/ it = cmdList.listIterator(); it.hasNext();) {
					String option = it.next();

					if (option.opEquals("-oac")) {
						it.set("-nosound");

						if (it.hasNext()) {
							it.next();
							it.remove();
						}

						break;
					}
				}

				pipe = new PipeProcess(System.currentTimeMillis().toString() ~ "tsmuxerout.ts");

				TSMuxerVideo ts = new TSMuxerVideo(configuration);
				File f = new File(configuration.getTempFolder(), "pms-tsmuxer.meta");
				String[] cmd = [ ts.executable(), f.getAbsolutePath(), pipe.getInputPipe() ];
				pw = new ProcessWrapperImpl(cmd, params);

				PipeIPCProcess ffVideoPipe = new PipeIPCProcess(System.currentTimeMillis().toString() ~ "ffmpegvideo", System.currentTimeMillis().toString() ~ "videoout", false, true);

				cmdList.add("-o");
				cmdList.add(ffVideoPipe.getInputPipe());

				OutputParams ffparams = new OutputParams(configuration);
				ffparams.maxBufferSize = 1;
				ffparams.stdin = params.stdin;

				String[] cmdArray = new String[cmdList.size()];
				cmdList.toArray(cmdArray);
				ProcessWrapperImpl ffVideo = new ProcessWrapperImpl(cmdArray, ffparams);

				ProcessWrapper ff_video_pipe_process = ffVideoPipe.getPipeProcess();
				pw.attachProcess(ff_video_pipe_process);
				ff_video_pipe_process.runInNewThread();
				ffVideoPipe.deleteLater();

				pw.attachProcess(ffVideo);
				ffVideo.runInNewThread();

				String aid = null;
				if (media !is null && media.getAudioTracksList().size() > 1 && params.aid !is null) {
					if (media.getContainer() !is null && (media.getContainer().opEquals(FormatConfiguration.AVI) || media.getContainer().opEquals(FormatConfiguration.FLV))) {
						// TODO confirm (MP4s, OGMs and MOVs already tested: first aid is 0; AVIs: first aid is 1)
						// for AVIs, FLVs ans MOVs mencoder starts audio tracks numbering from 1
						aid = (params.aid.getId() + 1).toString();
					} else {
						// everything else from 0
						aid = params.aid.getId().toString();
					}
				}

				PipeIPCProcess ffAudioPipe = new PipeIPCProcess(System.currentTimeMillis().toString() ~ "ffmpegaudio01", System.currentTimeMillis() + "audioout", false, true);
				StreamModifier sm = new StreamModifier();
				sm.setPcm(pcm);
				sm.setDtsEmbed(dtsRemux);
				sm.setSampleFrequency(48000);
				sm.setBitsPerSample(16);

				String mixer = null;
				if (pcm && !dtsRemux) {
					mixer = getLPCMChannelMappingForMencoder(params.aid); // LPCM always outputs 5.1/7.1 for multichannel tracks. Downmix with player if needed!
				}

				sm.setNbChannels(channels);

				// it seems the -really-quiet prevents mencoder to stop the pipe output after some time...
				// -mc 0.1 make the DTS-HD extraction works better with latest mencoder builds, and makes no impact on the regular DTS one
				String[] ffmpegLPCMextract = [
					executable(),
					"-ss", "0",
					fileName,
					"-really-quiet",
					"-msglevel", "statusline=2",
					"-channels", "" ~ channels,
					"-ovc", "copy",
					"-of", "rawaudio",
					"-mc", dtsRemux ? "0.1" : "0",
					"-noskip",
					(aid is null) ? "-quiet" : "-aid", (aid is null) ? "-quiet" : aid,
					"-oac", (ac3Remux || dtsRemux) ? "copy" : "pcm",
					(isNotBlank(mixer) && !channels_filter_present) ? "-af" : "-quiet", (isNotBlank(mixer) && !channels_filter_present) ? mixer : "-quiet",
					"-srate", "48000",
					"-o", ffAudioPipe.getInputPipe()
				];

				if (!params.mediaRenderer.isMuxDTSToMpeg()) { // no need to use the PCM trick when media renderer supports DTS
					ffAudioPipe.setModifier(sm);
				}

				if (media !is null && media.getDvdtrack() > 0) {
					ffmpegLPCMextract[3] = "-dvd-device";
					ffmpegLPCMextract[4] = fileName;
					ffmpegLPCMextract[5] = "dvd://" ~ media.getDvdtrack();
				} else if (params.stdin !is null) {
					ffmpegLPCMextract[3] = "-";
				}

				if (fileName.toLowerCase().endsWith(".evo")) {
					ffmpegLPCMextract[4] = "-psprobe";
					ffmpegLPCMextract[5] = "1000000";
				}

				if (params.timeseek > 0) {
					ffmpegLPCMextract[2] = params.timeseek.toString();
				}

				OutputParams ffaudioparams = new OutputParams(configuration);
				ffaudioparams.maxBufferSize = 1;
				ffaudioparams.stdin = params.stdin;
				ProcessWrapperImpl ffAudio = new ProcessWrapperImpl(ffmpegLPCMextract, ffaudioparams);

				params.stdin = null;

				PrintWriter pwMux = new PrintWriter(f);
				pwMux.println("MUXOPT --no-pcr-on-video-pid --no-asyncio --new-audio-pes --vbr --vbv-len=500");
				String videoType = "V_MPEG-2";

				if (params.no_videoencode && params.forceType !is null) {
					videoType = params.forceType;
				}

				String fps = "";
				if (params.forceFps !is null) {
					fps = "fps=" ~ params.forceFps ~ ", ";
				}

				String audioType;
				if (ac3Remux) {
					audioType = "A_AC3";
				} else if (dtsRemux) {
					if (params.mediaRenderer.isMuxDTSToMpeg()) {
						//renderer can play proper DTS track
						audioType = "A_DTS";
					} else {
						// DTS padded in LPCM trick
						audioType = "A_LPCM";
					}
				} else {
					// PCM
					audioType = "A_LPCM";
				}


				// mencoder bug (confirmed with mencoder r35003 + ffmpeg 0.11.1):
				// audio delay is ignored when playing from file start (-ss 0)
				// override with tsmuxer.meta setting
				String timeshift = "";
				if (mencoderAC3RemuxAudioDelayBug) {
					timeshift = "timeshift=" ~ params.aid.getAudioProperties().getAudioDelay().toString() ~ "ms, ";
				}

				pwMux.println(videoType ~ ", \"" ~ ffVideoPipe.getOutputPipe() ~ "\", " ~ fps ~ "level=4.1, insertSEI, contSPS, track=1");
				pwMux.println(audioType ~ ", \"" ~ ffAudioPipe.getOutputPipe() ~ "\", " ~ timeshift ~ "track=2");
				pwMux.close();

				ProcessWrapper pipe_process = pipe.getPipeProcess();
				pw.attachProcess(pipe_process);
				pipe_process.runInNewThread();

				try {
					Thread.sleep(50);
				} catch (InterruptedException e) {
				}

				pipe.deleteLater();
				params.input_pipes[0] = pipe;

				ProcessWrapper ff_pipe_process = ffAudioPipe.getPipeProcess();
				pw.attachProcess(ff_pipe_process);
				ff_pipe_process.runInNewThread();

				try {
					Thread.sleep(50);
				} catch (InterruptedException e) {
				}

				ffAudioPipe.deleteLater();
				pw.attachProcess(ffAudio);
				ffAudio.runInNewThread();
			}
		} else {
			bool directpipe = Platform.isMac() || Platform.isFreeBSD();

			if (directpipe) {
				cmdList.add("-o");
				cmdList.add("-");
				cmdList.add("-really-quiet");
				cmdList.add("-msglevel");
				cmdList.add("statusline=2");
				params.input_pipes = new PipeProcess[2];
			} else {
				pipe = new PipeProcess("mencoder" ~ System.currentTimeMillis().toString(), (pcm || dtsRemux) ? null : params);
				params.input_pipes[0] = pipe;
				cmdList.add("-o");
				cmdList.add(pipe.getInputPipe());
			}

			String[] cmdArray = new String[ cmdList.size() ];
			cmdList.toArray(cmdArray);

			cmdArray = finalizeTranscoderArgs(
				fileName,
				dlna,
				media,
				params,
				cmdArray
			);

			pw = new ProcessWrapperImpl(cmdArray, params);

			if (!directpipe) {
				ProcessWrapper mkfifo_process = pipe.getPipeProcess();
				pw.attachProcess(mkfifo_process);
				mkfifo_process.runInNewThread();

				try {
					Thread.sleep(50);
				} catch (InterruptedException e) { }

				pipe.deleteLater();
			}
		}

		pw.runInNewThread();

		try {
			Thread.sleep(100);
		} catch (InterruptedException e) { }

		return pw;
	}

	override
	public String mimeType() {
		return HTTPResource.VIDEO_TRANSCODE;
	}

	override
	public String name() {
		return "MEncoder";
	}

	override
	public int type() {
		return Format.VIDEO;
	}

	private String[] getSpecificCodecOptions(
		String codecParam,
		DLNAMediaInfo media,
		OutputParams params,
		String filename,
		String externalSubtitlesFileName,
		bool enable,
		bool verifyOnly
	) {
		StringBuilder sb = new StringBuilder();
		String codecs = enable ? DEFAULT_CODEC_CONF_SCRIPT : "";
		codecs ~= "\n" ~ codecParam;
		StringTokenizer stLines = new StringTokenizer(codecs, "\n");

		try {
			Interpreter interpreter = new Interpreter();
			interpreter.setStrictJava(true);
			ArrayList/*<String>*/ types = CodecUtil.getPossibleCodecs();
			int rank = 1;

			if (types !is null) {
				foreach (String type ; types) {
					int r = rank++;
					interpreter.set("" ~ type, r);
					String secondaryType = "dummy";

					if ("matroska".opEquals(type)) {
						secondaryType = "mkv";
						interpreter.set(secondaryType, r);
					} else if ("rm".opEquals(type)) {
						secondaryType = "rmvb";
						interpreter.set(secondaryType, r);
					} else if ("mpeg2video".opEquals(type)) {
						secondaryType = "mpeg2";
						interpreter.set(secondaryType, r);
					} else if ("mpeg1video".opEquals(type)) {
						secondaryType = "mpeg1";
						interpreter.set(secondaryType, r);
					}

					if (media.getContainer() !is null && (media.getContainer().opEquals(type) || media.getContainer().opEquals(secondaryType))) {
						interpreter.set("container", r);
					} else if (media.getCodecV() !is null && (media.getCodecV().opEquals(type) || media.getCodecV().opEquals(secondaryType))) {
						interpreter.set("vcodec", r);
					} else if (params.aid !is null && params.aid.getCodecA() !is null && params.aid.getCodecA().opEquals(type)) {
						interpreter.set("acodec", r);
					}
				}
			} else {
				return null;
			}

			interpreter.set("filename", filename);
			interpreter.set("audio", params.aid !is null);
			interpreter.set("subtitles", params.sid !is null);
			interpreter.set("srtfile", externalSubtitlesFileName);

			if (params.aid !is null) {
				interpreter.set("samplerate", params.aid.getSampleRate());
			}

			String framerate = media.getValidFps(false);

			try {
				if (framerate !is null) {
					interpreter.set("framerate", Double.parseDouble(framerate).toString());
				}
			} catch (NumberFormatException e) {
				LOGGER._debug("Could not parse framerate from \"" ~ framerate ~ "\"");
			}

			interpreter.set("duration", media.getDurationInSeconds());

			if (params.aid !is null) {
				interpreter.set("channels", params.aid.getAudioProperties().getNumberOfChannels());
			}

			interpreter.set("height", media.getHeight());
			interpreter.set("width", media.getWidth());

			while (stLines.hasMoreTokens()) {
				String line = stLines.nextToken();

				if (!line.startsWith("#") && line.trim().length() > 0) {
					int separator = line.indexOf("::");

					if (separator > -1) {
						String key = null;

						try {
							key = line.substring(0, separator).trim();
							String value = line.substring(separator + 2).trim();

							if (value.length() > 0) {
								if (key.length() == 0) {
									key = "1 == 1";
								}

								Object result = interpreter.eval(key);

								if (result !is null && cast(bool)result !is null && cast(bool) result) {
									sb.append(" ");
									sb.append(value);
								}
							}
						} catch (Throwable e) {
							LOGGER._debug("Error while executing: " ~ key ~ " : " ~ e.getMessage());

							if (verifyOnly) {
								String[] result = ["@@Error while parsing: " ~ e.getMessage()];
								return result;
							}
						}
					} else if (verifyOnly) {
						String[] result = ["@@Malformatted line: " ~ line];
						return result;
					}
				}
			}
		} catch (EvalError e) {
			LOGGER._debug("BeanShell error: " ~ e.getMessage());
		}

		String completeLine = sb.toString();
		ArrayList/*<String>*/ args = new ArrayList/*<String>*/();
		StringTokenizer st = new StringTokenizer(completeLine, " ");

		while (st.hasMoreTokens()) {
			String arg = st.nextToken().trim();

			if (arg.length() > 0) {
				args.add(arg);
			}
		}

		String[] definitiveArgs = new String[args.size()];
		args.toArray(definitiveArgs);

		return definitiveArgs;
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

			if (id.opEquals(Format.Identifier.ISO)
					|| id.opEquals(Format.Identifier.MKV)
					|| id.opEquals(Format.Identifier.MPG)) {
				return true;
			}
		}

		return false;
	}
}
