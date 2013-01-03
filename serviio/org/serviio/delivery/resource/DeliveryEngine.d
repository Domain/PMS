module org.serviio.delivery.resource.DeliveryEngine;

import java.io.IOException;
import java.util.List;
import org.serviio.delivery.Client;
import org.serviio.delivery.DeliveryContainer;
import org.serviio.delivery.MediaFormatProfileResource;
import org.serviio.dlna.MediaFormatProfile;
import org.serviio.dlna.UnsupportedDLNAMediaFileFormatException;
import org.serviio.library.entities.MediaItem;
import org.serviio.profile.DeliveryQuality.QualityType;
import org.serviio.profile.Profile;

public abstract interface DeliveryEngine<RI : MediaFormatProfileResource, MI : MediaItem>
{
  public abstract List<RI> getMediaInfoForProfile(MI paramMI, Profile paramProfile);

  public abstract RI getMediaInfoForMediaItem(MI paramMI, MediaFormatProfile paramMediaFormatProfile, QualityType paramQualityType, Profile paramProfile)
    throws UnsupportedDLNAMediaFileFormatException;

  public abstract DeliveryContainer deliver(MI paramMI, MediaFormatProfile paramMediaFormatProfile, QualityType paramQualityType, Double paramDouble1, Double paramDouble2, Client paramClient)
    throws UnsupportedDLNAMediaFileFormatException, IOException;
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.delivery.resource.DeliveryEngine
 * JD-Core Version:    0.6.2
 */