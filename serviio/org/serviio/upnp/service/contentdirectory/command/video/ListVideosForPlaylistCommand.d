module org.serviio.upnp.service.contentdirectory.command.video.ListVideosForPlaylistCommand;

import java.util.List;
import org.serviio.library.entities.AccessGroup;
import org.serviio.library.entities.Video;
import org.serviio.library.local.service.VideoService;
import org.serviio.profile.Profile;
import org.serviio.upnp.service.contentdirectory.ObjectType;
import org.serviio.upnp.service.contentdirectory.classes.ObjectClassType;

public class ListVideosForPlaylistCommand : AbstractVideosRetrievalCommand
{
  public this(String contextIdentifier, ObjectType objectType, ObjectClassType containerClassType, ObjectClassType itemClassType, Profile rendererProfile, AccessGroup accessGroup, String idPrefix, int startIndex, int count)
  {
    super(contextIdentifier, objectType, containerClassType, itemClassType, rendererProfile, accessGroup, idPrefix, startIndex, count);
  }

  protected List<Video> retrieveEntityList()
  {
    List<Video> videos = VideoService.getListOfVideosForPlaylist(new Long(getInternalObjectId()), accessGroup, startIndex, count);
    return videos;
  }

  public int retrieveItemCount()
  {
    return VideoService.getNumberOfVideosForPlaylist(new Long(getInternalObjectId()), accessGroup);
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.upnp.service.contentdirectory.command.video.ListVideosForPlaylistCommand
 * JD-Core Version:    0.6.2
 */