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
module net.pms.newgui.ImagePanel;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

////import javax.swing.*;
////import java.awt.*;
//import java.awt.geom.AffineTransform;
//import java.awt.image.RenderedImage;

class ImagePanel : JPanel {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!ImagePanel();
	private static final long serialVersionUID = -6709086531128513425L;
	protected RenderedImage source;
	protected int originX;
	protected int originY;

	public this() {
		this(null);
	}

	public this(RenderedImage renderedimage) {
		source = null;
		originX = 0;
		originY = 0;
		setLayout(null);
		if (renderedimage !is null) {
			source = renderedimage;
			int i = source.getWidth();
			int j = source.getHeight();
			Insets insets = getInsets();
			Dimension dimension =
				new Dimension(
				i + insets.left + insets.right,
				j + insets.top + insets.bottom);
			setPreferredSize(dimension);
		}
	}

	public void setOrigin(int i, int j) {
		originX = i;
		originY = j;
		repaint();
	}

	public Point getOrigin() {
		return new Point(originX, originY);
	}

	public void set(RenderedImage renderedimage) {
		source = renderedimage;
		int i = 0;
		int j = 0;
		if (renderedimage !is null) {
			i = source.getWidth();
			j = source.getHeight();
		}
		Insets insets = getInsets();
		Dimension dimension =
			new Dimension(
			i + insets.left + insets.right,
			j + insets.top + insets.bottom);
		setPreferredSize(dimension);
		revalidate();
		repaint();
	}

	public void set(RenderedImage renderedimage, int i, int j) {
		if (renderedimage is null) {
			originX = 0;
			originY = 0;
		} else {
			originX = i;
			originY = j;
		}
		set(renderedimage);
	}

	public RenderedImage getSource() {
		return source;
	}

	public synchronized void paintComponent(Graphics g) {
		Graphics2D graphics2d = cast(Graphics2D) g;
		if (source is null) {
			graphics2d.setColor(getBackground());
			graphics2d.fillRect(0, 0, getWidth(), getHeight());
			return;
		}
		Rectangle rectangle = graphics2d.getClipBounds();
		graphics2d.setColor(getBackground());
		graphics2d.fillRect(
			rectangle.x,
			rectangle.y,
			rectangle.width,
			rectangle.height);
		Insets insets = getInsets();
		int i = insets.left + originX;
		int j = insets.top + originY;
		try {
			graphics2d.drawRenderedImage(
				source,
				AffineTransform.getTranslateInstance(i, j));
		} catch (OutOfMemoryError e) {
			LOGGER._debug("Caught exception", e);
		}
	}
}
