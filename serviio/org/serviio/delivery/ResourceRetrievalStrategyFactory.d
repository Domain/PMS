module org.serviio.delivery.ResourceRetrievalStrategyFactory;

import org.serviio.upnp.service.contentdirectory.classes.Resource.ResourceType;

public class ResourceRetrievalStrategyFactory
{
  public ResourceRetrievalStrategy instantiateResourceRetrievalStrategy(ResourceType resourceType)
  {
    if (resourceType == ResourceType.MEDIA_ITEM)
      return new MediaResourceRetrievalStrategy();
    if (resourceType == ResourceType.COVER_IMAGE)
      return new CoverImageRetrievalStrategy();
    if (resourceType == ResourceType.SUBTITLE) {
      return new SubtitlesRetrievalStrategy();
    }
    throw new RuntimeException("Unsupported resource type: " + resourceType);
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.delivery.ResourceRetrievalStrategyFactory
 * JD-Core Version:    0.6.2
 */