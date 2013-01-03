module org.serviio.restlet.ServiioXstreamRepresentation;

import com.thoughtworks.xstream.XStream;
import com.thoughtworks.xstream.converters.collections.CollectionConverter;
import com.thoughtworks.xstream.mapper.ClassAliasingMapper;
import org.restlet.data.CharacterSet;
import org.restlet.data.MediaType;
import org.restlet.ext.xstream.XstreamRepresentation;
import org.restlet.representation.Representation;
import org.serviio.library.metadata.MediaFileType;
import org.serviio.ui.representation.ActionRepresentation;
import org.serviio.ui.representation.ApplicationRepresentation;
import org.serviio.ui.representation.BrowsingCategory;
import org.serviio.ui.representation.ConsoleSettingsRepresentation;
import org.serviio.ui.representation.DataValue;
import org.serviio.ui.representation.LibraryStatusRepresentation;
import org.serviio.ui.representation.LicenseRepresentation;
import org.serviio.ui.representation.MetadataRepresentation;
import org.serviio.ui.representation.OnlinePlugin;
import org.serviio.ui.representation.OnlinePluginsRepresentation;
import org.serviio.ui.representation.OnlineRepository;
import org.serviio.ui.representation.PresentationRepresentation;
import org.serviio.ui.representation.ReferenceDataRepresentation;
import org.serviio.ui.representation.RemoteAccessRepresentation;
import org.serviio.ui.representation.RendererRepresentation;
import org.serviio.ui.representation.RepositoryRepresentation;
import org.serviio.ui.representation.ServiceStatusRepresentation;
import org.serviio.ui.representation.SharedFolder;
import org.serviio.ui.representation.StatusRepresentation;
import org.serviio.ui.representation.TranscodingRepresentation;
import org.serviio.upnp.service.contentdirectory.rest.representation.ContentDirectoryRepresentation;
import org.serviio.upnp.service.contentdirectory.rest.representation.ContentURLRepresentation;
import org.serviio.upnp.service.contentdirectory.rest.representation.DirectoryObjectRepresentation;
import org.serviio.upnp.service.contentdirectory.rest.representation.OnlineIdentifierRepresentation;

public class ServiioXstreamRepresentation!(T) : XstreamRepresentation!(T)
{
  public this(T object)
  {
    super(object);
  }

  public this(MediaType mediaType, T object) {
    super(mediaType, object);
  }

  public this(Representation representation) {
    super(representation);
  }

  public MediaType getMediaType()
  {
    return MediaType.APPLICATION_XML;
  }

  protected XStream createXstream(MediaType arg0)
  {
    XStream xs = super.createXstream(arg0);
    xs.alias("serviceStatus", ServiceStatusRepresentation.class);
    xs.alias("action", ActionRepresentation.class);
    xs.alias("application", ApplicationRepresentation.class);
    xs.alias("license", LicenseRepresentation.class);
    xs.alias("libraryStatus", LibraryStatusRepresentation.class);
    xs.alias("metadata", MetadataRepresentation.class);
    xs.alias("refdata", ReferenceDataRepresentation.class);
    xs.alias("repository", RepositoryRepresentation.class);
    xs.alias("result", ResultRepresentation.class);
    xs.alias("status", StatusRepresentation.class);
    xs.alias("transcoding", TranscodingRepresentation.class);
    xs.alias("renderer", RendererRepresentation.class);
    xs.alias("presentation", PresentationRepresentation.class);
    xs.alias("consoleSettings", ConsoleSettingsRepresentation.class);
    xs.alias("remoteAccess", RemoteAccessRepresentation.class);
    xs.alias("plugins", OnlinePluginsRepresentation.class);

    xs.alias("item", DataValue.class);
    xs.alias("sharedFolder", SharedFolder.class);
    xs.alias("fileType", MediaFileType.class);
    xs.alias("browsingCategory", BrowsingCategory.class);
    xs.alias("onlineRepository", OnlineRepository.class);
    xs.alias("onlinePlugin", OnlinePlugin.class);

    xs.alias("contentDirectory", ContentDirectoryRepresentation.class);
    xs.alias("object", DirectoryObjectRepresentation.class);
    xs.alias("contentUrl", ContentURLRepresentation.class);
    xs.alias("identifier", OnlineIdentifierRepresentation.class);

    ClassAliasingMapper mapper = new ClassAliasingMapper(xs.getMapper());
    mapper.addClassAlias("id", Long.class);
    xs.registerLocalConverter(SharedFolder.class, "accessGroupIds", new CollectionConverter(mapper));
    xs.registerLocalConverter(OnlineRepository.class, "accessGroupIds", new CollectionConverter(mapper));

    return xs;
  }

  public CharacterSet getCharacterSet()
  {
    return CharacterSet.UTF_8;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.restlet.ServiioXstreamRepresentation
 * JD-Core Version:    0.6.2
 */