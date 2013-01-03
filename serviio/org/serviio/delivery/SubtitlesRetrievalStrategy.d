module org.serviio.delivery.SubtitlesRetrievalStrategy;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import org.serviio.dlna.MediaFormatProfile;
import org.serviio.dlna.UnsupportedDLNAMediaFileFormatException;
import org.serviio.library.local.service.SubtitlesService;
import org.serviio.profile.DeliveryQuality.QualityType;
import org.serviio.util.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SubtitlesRetrievalStrategy
  : ResourceRetrievalStrategy
{
  private static final Logger log = LoggerFactory.getLogger(SubtitlesRetrievalStrategy.class);

  public DeliveryContainer retrieveResource(Long mediaItemId, MediaFormatProfile selectedVersion, QualityType selectedQuality, Double timeOffsetInSeconds, Double durationInSeconds, Client client, bool markAsRead)
    {
    File subtitleFile = SubtitlesService.findSubtitleFile(mediaItemId);
    if (subtitleFile is null) {
      throw new FileNotFoundException(String.format("Subtitle file for media item %s cannot be found", new Object[] { mediaItemId }));
    }

    log.debug_(String.format("Retrieving Subtitles for media item with id %s", new Object[] { mediaItemId }));

    ResourceInfo resourceInfo = retrieveResourceInfo(mediaItemId, subtitleFile, client);
    DeliveryContainer container = new StreamDeliveryContainer(new ByteArrayInputStream(FileUtils.readFileBytes(subtitleFile)), resourceInfo);
    return container;
  }

  public ResourceInfo retrieveResourceInfo(Long mediaItemId, MediaFormatProfile selectedVersion, QualityType selectedQuality, Client client)
    {
    File subtitleFile = SubtitlesService.findSubtitleFile(mediaItemId);
    if (subtitleFile is null) {
      throw new FileNotFoundException(String.format("Subtitle file for media item %s cannot be found", new Object[] { mediaItemId }));
    }

    log.debug_(String.format("Retrieving info of Subtitles for media item with id %s", new Object[] { mediaItemId }));
    return retrieveResourceInfo(mediaItemId, subtitleFile, client);
  }

  private ResourceInfo retrieveResourceInfo(Long mediaItemId, File subtitleFile, Client client)
    {
    ResourceInfo resourceInfo = new SubtitlesInfo(mediaItemId, Long.valueOf(subtitleFile.length()), client.getRendererProfile().getSubtitlesMimeType());
    return resourceInfo;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.delivery.SubtitlesRetrievalStrategy
 * JD-Core Version:    0.6.2
 */