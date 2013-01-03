module org.serviio.delivery.resource.transcode.TranscodingDeliveryStrategy;

import java.io.IOException;
import org.serviio.delivery.Client;
import org.serviio.delivery.DeliveryListener;
import org.serviio.library.entities.MediaItem;

public abstract interface TranscodingDeliveryStrategy<T>
{
  public abstract StreamDescriptor createInputStream(TranscodingJobListener paramTranscodingJobListener, Client paramClient)
    throws IOException;

  public abstract TranscodingJobListener invokeTranscoder(String paramString, MediaItem paramMediaItem, Double paramDouble1, Double paramDouble2, TranscodingDefinition paramTranscodingDefinition, Client paramClient, DeliveryListener paramDeliveryListener)
    throws IOException;
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.delivery.resource.transcode.TranscodingDeliveryStrategy
 * JD-Core Version:    0.6.2
 */