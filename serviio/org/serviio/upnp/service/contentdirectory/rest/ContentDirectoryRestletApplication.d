module org.serviio.upnp.service.contentdirectory.rest.ContentDirectoryRestletApplication;

import org.restlet.Application;
import org.restlet.Restlet;
import org.restlet.routing.Router;
import org.serviio.ui.resources.server.ApplicationServerResource;
import org.serviio.ui.resources.server.PingServerResource;
import org.serviio.upnp.service.contentdirectory.rest.resources.server.CDSBrowseServerResource;
import org.serviio.upnp.service.contentdirectory.rest.resources.server.CDSRetrieveMediaServerResource;
import org.serviio.upnp.service.contentdirectory.rest.resources.server.LoginServerResource;
import org.serviio.upnp.service.contentdirectory.rest.resources.server.LogoutServerResource;

public class ContentDirectoryRestletApplication : Application
{
  public static final String APP_CONTEXT = "/cds";

  public Restlet createInboundRoot()
  {
    Router router = new Router(getContext());
    router.setDefaultMatchingMode(1);

    router.attach("/browse/{profile}/{objectId}/{browseFlag}/{objectType}/{start}/{count}", CDSBrowseServerResource.class);
    router.attach("/resource", CDSRetrieveMediaServerResource.class);
    router.attach("/login", LoginServerResource.class);
    router.attach("/logout", LogoutServerResource.class);
    router.attach("/application", ApplicationServerResource.class);
    router.attach("/ping", PingServerResource.class);

    return router;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.upnp.service.contentdirectory.rest.ContentDirectoryRestletApplication
 * JD-Core Version:    0.6.2
 */