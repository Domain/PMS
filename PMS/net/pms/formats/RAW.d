module net.pms.formats.RAW;

import java.util.ArrayList;
import java.util.List;

import net.pms.PMS;
import net.pms.configuration.RendererConfiguration;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.dlna.InputFile;
import net.pms.encoders.Player;
import net.pms.encoders.RAWThumbnailer;
import net.pms.io.OutputParams;
import net.pms.io.ProcessWrapperImpl;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class RAW : JPG {
	private static immutable Logger LOGGER = LoggerFactory.getLogger(RAW.class);

	/**
	 * {@inheritDoc} 
	 */
	override
	public Identifier getIdentifier() {
		return Identifier.RAW;
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public String[] getId() {
		String[] id = [ "arw", "cr2", "crw", "dng", "raf", "mrw", "nef",
				"pef", "srf", "orf" ];
		return id;
	}

	/**
	 * @deprecated Use {@link #isCompatible(DLNAMediaInfo, RendererConfiguration)} instead.
	 * <p>
	 * Returns whether or not a format can be handled by the PS3 natively.
	 * This means the format can be streamed to PS3 instead of having to be
	 * transcoded.
	 * 
	 * @return True if the format can be handled by PS3, false otherwise.
	 */
	deprecated
	override
	public bool ps3compatible() {
		return false;
	}

	override
	public ArrayList/*<Class<? : Player>>*/ getProfiles() {
		ArrayList/*<Class<? : Player>>*/ profiles = new ArrayList/*<Class<? : Player>>*/();
		foreach (String engine ; PMS.getConfiguration().getEnginesAsList(PMS.get().getRegistry())) {
			if (engine.equals(RAWThumbnailer.ID)) {
				profiles.add(RAWThumbnailer.class);
			}
		}
		return profiles;
	}

	override
	public bool transcodable() {
		return true;
	}

	override
	public void parse(DLNAMediaInfo media, InputFile file, int type, RendererConfiguration renderer) {
		try {
			OutputParams params = new OutputParams(PMS.getConfiguration());
			params.waitbeforestart = 1;
			params.minBufferSize = 1;
			params.maxBufferSize = 5;
			params.hidebuffer = true;


			String cmdArray[] = new String[4];
			cmdArray[0] = PMS.getConfiguration().getDCRawPath();
			cmdArray[1] = "-i";
			cmdArray[2] = "-v";
			if (file.getFile() !is null) {
				cmdArray[3] = file.getFile().getAbsolutePath();
			}

			params.log = true;
			ProcessWrapperImpl pw = new ProcessWrapperImpl(cmdArray, params, true, false);
			pw.runInSameThread();

			List<String> list = pw.getOtherResults();
			for (String s : list) {
				if (s.startsWith("Thumb size:  ")) {
					String sz = s.substring(13);
					media.setWidth(Integer.parseInt(sz.substring(0, sz.indexOf("x")).trim()));
					media.setHeight(Integer.parseInt(sz.substring(sz.indexOf("x") + 1).trim()));
				}
			}

			if (media.getWidth() > 0) {

				media.setThumb(RAWThumbnailer.getThumbnail(params, file.getFile().getAbsolutePath()));
				if (media.getThumb() !is null) {
					media.setSize(media.getThumb().length);
				}

				media.setCodecV("jpg");
				media.setContainer("jpg");
			}

			media.finalize(type, file);
			media.setMediaparsed(true);
		} catch (Exception e) {
			LOGGER._debug("Caught exception", e);
		}
	}
}
