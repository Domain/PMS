module org.serviio.upnp.service.contentdirectory.command.audio.ListSongsForComposerAndAlbumCommand;

import org.serviio.library.entities.AccessGroup;
import org.serviio.library.entities.Person.RoleType;
import org.serviio.profile.Profile;
import org.serviio.upnp.service.contentdirectory.ObjectType;
import org.serviio.upnp.service.contentdirectory.classes.ObjectClassType;

public class ListSongsForComposerAndAlbumCommand : AbstractSongsForRoleAndAlbumRetrievalCommand
{
  public this(String contextIdentifier, ObjectType objectType, ObjectClassType containerClassType, ObjectClassType itemClassType, Profile rendererProfile, AccessGroup accessGroup, String idPrefix, int startIndex, int count)
  {
    super(contextIdentifier, objectType, containerClassType, itemClassType, rendererProfile, accessGroup, idPrefix, startIndex, count, RoleType.COMPOSER);
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.upnp.service.contentdirectory.command.audio.ListSongsForComposerAndAlbumCommand
 * JD-Core Version:    0.6.2
 */