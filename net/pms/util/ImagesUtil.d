module net.pms.util.ImagesUtil;

//import mediautil.gen.Log;
//import mediautil.image.jpeg.LLJTran;
//import mediautil.image.jpeg.LLJTranException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.all;

public class ImagesUtil {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!ImagesUtil();

	public static InputStream getAutoRotateInputStreamImage(InputStream input, int exifOrientation) {
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		try {
			_auto(input, baos, exifOrientation);
		} catch (Exception e) {
			logger.error("Error in auto rotate", e);
			return null;
		}
		return new ByteArrayInputStream(baos.toByteArray());
	}

	public static void _auto(InputStream input, OutputStream output, int exifOrientation) {
		// convert sanselan exif orientation -> llj operation
		int op = 0;
		switch (exifOrientation) {
			case 1:
				op = 0;
				break;
			case 2:
				op = 1;
				break;
			case 3:
				op = 6;
				break;
			case 4:
				op = 2;
				break;
			case 5:
				op = 3;
				break;
			case 6:
				op = 5;
				break;
			case 7:
				op = 4;
				break;
			case 8:
				op = 7;
				break;
			default:
				op = 0;
		}

		// Raise the Debug Level which is normally LEVEL_INFO. Only Warning
		// messages will be printed by MediaUtil.
		Log.debugLevel = Log.LEVEL_NONE;

		// 1. Initialize LLJTran and Read the entire Image including Appx markers
		LLJTran llj = new LLJTran(input);
		// If you pass the 2nd parameter as false, Exif information is not
		// loaded and hence will not be written.
		llj.read(LLJTran.READ_ALL, true);

		// 2. Transform the image using default options along with
		// transformation of the Orientation tags. Try other combinations of
		// LLJTran_XFORM.. flags. Use a jpeg with partial MCU (partialMCU.jpg)
		// for testing LLJTran.XFORM_TRIM and LLJTran.XFORM_ADJUST_EDGES
		int options = LLJTran.OPT_DEFAULTS | LLJTran.OPT_XFORM_ORIENTATION;
		llj.transform(op, options);

		// 4. Save the Image which is already transformed as specified by the
		//    input transformation in Step 2, along with the Exif header.
		OutputStream _out = new BufferedOutputStream(output);
		llj.save(_out, LLJTran.OPT_WRITE_ALL);
		_out.close();

		// Cleanup
		input.close();
		llj.freeMemory();
	}
}
