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
module net.pms.encoders.FFMpegDVRMSRemux;

import com.jgoodies.forms.builder.PanelBuilder;
import com.jgoodies.forms.factories.Borders;
import com.jgoodies.forms.layout.CellConstraints;
import com.jgoodies.forms.layout.FormLayout;
import net.pms.Messages;
import net.pms.PMS;
import net.pms.configuration.PmsConfiguration;
import net.pms.configuration.RendererConfiguration;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.dlna.DLNAResource;
import net.pms.formats.Format;
import net.pms.io.OutputParams;
import net.pms.io.ProcessWrapper;
import net.pms.io.ProcessWrapperImpl;
import org.apache.commons.lang.StringUtils;

import javax.swing.*;
import java.awt.*;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class FFMpegDVRMSRemux : Player {
	private JTextField altffpath;
	public static final String ID = "ffmpegdvrmsremux";

	override
	public int purpose() {
		return MISC_PLAYER;
	}

	override
	public String id() {
		return ID;
	}

	override
	public bool isTimeSeekable() {
		return true;
	}

	override
	public bool avisynth() {
		return false;
	}

	public FFMpegDVRMSRemux() {
	}

	override
	public String name() {
		return "FFmpeg DVR-MS Remux";
	}

	override
	public int type() {
		return Format.VIDEO;
	}

	@Deprecated
	protected String[] getDefaultArgs() {
		return new String[] {
			"-vcodec", "copy",
			"-acodec", "copy",
			"-threads", "2",
			"-g", "1",
			"-qscale", "1",
			"-qmin", "2",
			"-f", "vob",
			"-copyts"
		};
	}

	override
	@Deprecated
	public String[] args() {
		return getDefaultArgs();

	}

	override
	public String mimeType() {
		return "video/mpeg";
	}

	override
	public String executable() {
		return PMS.getConfiguration().getFfmpegPath();
	}

	override
	public ProcessWrapper launchTranscode(
		String fileName,
		DLNAResource dlna,
		DLNAMediaInfo media,
		OutputParams params
	) throws IOException {
		return getFFMpegTranscode(fileName, dlna, media, params);
	}

	// pointless redirection of launchTranscode
	@Deprecated
	protected ProcessWrapperImpl getFFMpegTranscode(
		String fileName,
		DLNAResource dlna,
		DLNAMediaInfo media,
		OutputParams params
	) throws IOException {
		PmsConfiguration configuration = PMS.getConfiguration();
		String ffmpegAlternativePath = configuration.getFfmpegAlternativePath();
		List<String> cmdList = new ArrayList<String>();

		if (ffmpegAlternativePath !is null && ffmpegAlternativePath.length() > 0) {
			cmdList.add(ffmpegAlternativePath);
		} else {
			cmdList.add(executable());
		}

		if (params.timeseek > 0) {
			cmdList.add("-ss");
			cmdList.add("" + params.timeseek);
		}

		cmdList.add("-i");
		cmdList.add(fileName);

		for (String arg : args()) {
			cmdList.add(arg);
		}

		String customSettingsString = configuration.getFfmpegSettings();
		if (StringUtils.isNotBlank(customSettingsString)) {
			String[] customSettingsArray = StringUtils.split(customSettingsString);

			if (customSettingsArray !is null) {
				for (String option : customSettingsArray) {
					cmdList.add(option);
				}
			}
		}

		cmdList.add("pipe:");
		String[] cmdArray = new String[cmdList.size()];
		cmdList.toArray(cmdArray);

		cmdArray = finalizeTranscoderArgs(
			fileName,
			dlna,
			media,
			params,
			cmdArray
		);

		ProcessWrapperImpl pw = new ProcessWrapperImpl(cmdArray, params);
		pw.runInNewThread();

		return pw;
	}

	override
	public JComponent config() {
		FormLayout layout = new FormLayout(
			"left:pref, 3dlu, p, 3dlu, 0:grow",
			"p, 3dlu, p, 3dlu, 0:grow"
		);
		PanelBuilder builder = new PanelBuilder(layout);
		builder.setBorder(Borders.EMPTY_BORDER);
		builder.setOpaque(false);

		CellConstraints cc = new CellConstraints();

		JComponent cmp = builder.addSeparator(Messages.getString("FFMpegDVRMSRemux.1"), cc.xyw(1, 1, 5));
		cmp = (JComponent) cmp.getComponent(0);
		cmp.setFont(cmp.getFont().deriveFont(Font.BOLD));

		builder.addLabel(Messages.getString("FFMpegDVRMSRemux.0"), cc.xy(1, 3));
		altffpath = new JTextField(PMS.getConfiguration().getFfmpegAlternativePath());
		altffpath.addKeyListener(new KeyListener() {
			override
			public void keyPressed(KeyEvent e) {
			}

			override
			public void keyTyped(KeyEvent e) {
			}

			override
			public void keyReleased(KeyEvent e) {
				PMS.getConfiguration().setFfmpegAlternativePath(altffpath.getText());
			}
		});
		builder.add(altffpath, cc.xyw(3, 3, 3));

		return builder.getPanel();
	}

	override
	public bool isPlayerCompatible(RendererConfiguration mediaRenderer) {
		return mediaRenderer.isTranscodeToMPEGPSAC3();
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

			if (id.equals(Format.Identifier.DVRMS)) {
				return true;
			}
		}

		return false;
	}
}
