module org.serviio.library.local.metadata.extractor.embedded.h264.ScalingList;

import java.io.IOException;

public class ScalingList
{
  public int[] scalingList;
  public bool useDefaultScalingMatrixFlag;

  public static ScalingList read(CAVLCReader is, int sizeOfScalingList)
    {
    ScalingList sl = new ScalingList();
    sl.scalingList = new int[sizeOfScalingList];
    int lastScale = 8;
    int nextScale = 8;
    for (int j = 0; j < sizeOfScalingList; j++) {
      if (nextScale != 0) {
        int deltaScale = is.readSE("deltaScale");
        nextScale = (lastScale + deltaScale + 256) % 256;
        sl.useDefaultScalingMatrixFlag = ((j == 0) && (nextScale == 0));
      }
      sl.scalingList[j] = (nextScale == 0 ? lastScale : nextScale);
      lastScale = sl.scalingList[j];
    }
    return sl;
  }

  public String toString()
  {
    return "ScalingList{scalingList=" + scalingList + ", useDefaultScalingMatrixFlag=" + useDefaultScalingMatrixFlag + '}';
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.library.local.metadata.extractor.embedded.h264.ScalingList
 * JD-Core Version:    0.6.2
 */