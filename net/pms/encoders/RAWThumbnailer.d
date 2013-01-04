module net.pms.encoders.RAWThumbnailer;

import net.pms.PMS;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.dlna.DLNAResource;
import net.pms.formats.Format;
import net.pms.io.InternalJavaProcessImpl;
import net.pms.io.OutputParams;
import net.pms.io.ProcessWrapper;
import net.pms.io.ProcessWrapperImpl;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.lang.exceptions;
import java.io.InputStream;

public class RAWThumbnailer : Player {
	public const static String ID = "rawthumbs";

	protected String[] getDefaultArgs() {
		return ["-e", "-c"];
	}

	override
	public String[] args() {
		return getDefaultArgs();

	}

	override
	public JComponent config() {
		return null;
	}

	override
	public String executable() {
		return PMS.getConfiguration().getDCRawPath();
	}

	override
	public String id() {
		return ID;
	}

	override
	public ProcessWrapper launchTranscode(String fileName, DLNAResource dlna, DLNAMediaInfo media,
		OutputParams params) {

		params.waitbeforestart = 1;
		params.minBufferSize = 1;
		params.maxBufferSize = 5;
		params.hidebuffer = true;

		if (media is null || media.getThumb() is null) {
			return null;
		}

		if (media.getThumb().length == 0) {
			try {
				media.setThumb(getThumbnail(params, fileName));
			} catch (Exception e) {
				return null;
			}
		}

		byte copy[] = new byte[media.getThumb().length];
		System.arraycopy(media.getThumb(), 0, copy, 0, media.getThumb().length);
		media.setThumb(new byte[0]);

		ProcessWrapper pw = new InternalJavaProcessImpl(new ByteArrayInputStream(copy));
		return pw;
	}

	override
	public String mimeType() {
		return "image/jpeg";
	}

	override
	public String name() {
		return "dcraw Thumbnailer";
	}

	override
	public int purpose() {
		return MISC_PLAYER;
	}

	override
	public int type() {
		return Format.IMAGE;
	}

	public static byte[] getThumbnail(OutputParams params, String fileName) {
		params.log = false;

		String cmdArray[] = new String[4];
		cmdArray[0] = PMS.getConfiguration().getDCRawPath();
		cmdArray[1] = "-e";
		cmdArray[2] = "-c";
		cmdArray[3] = fileName;
		ProcessWrapperImpl pw = new ProcessWrapperImpl(cmdArray, params);
		pw.runInSameThread();


		InputStream _is = pw.getInputStream(0);
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		int n = -1;
		byte buffer[] = new byte[4096];
		while ((n = _is.read(buffer)) > -1) {
			baos.write(buffer, 0, n);
		}
		_is.close();
		byte b[] = baos.toByteArray();
		baos.close();
		return b;
	}

	/**
	 * {@inheritDoc}
	 */
	override
	public bool isCompatible(DLNAResource resource) {
		if (resource is null || resource.getFormat().getType() != Format.AUDIO) {
			return false;
		}

		if (resource.getMediaSubtitle() !is null) {
			// PMS does not support FFmpeg subtitles at the moment.
			return false;
		}

		Format format = resource.getFormat();

		if (format !is null) {
			Format.Identifier id = format.getIdentifier();

			if (id.opEquals(Format.Identifier.RAW)) {
				return true;
			}
		}

		return false;
	}
}
