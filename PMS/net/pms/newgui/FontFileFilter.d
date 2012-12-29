module net.pms.newgui.FontFileFilter;

import net.pms.Messages;

//import javax.swing.filechooser.FileFilter;
import java.io.File;

public class FontFileFilter : FileFilter {
	override
	public bool accept(File f) {
		String name = f.getName().toUpperCase();
		if (name.endsWith("TTC") || name.endsWith("TTF") || name.endsWith(".DESC"))
		{
			return true;
		}
		return f.isDirectory();
	}

	override
	public String getDescription() {
		return Messages.getString("FontFileFilter.3");
	}
}
