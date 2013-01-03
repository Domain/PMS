module org.serviio.ui.ApiRestletApplication;

import org.restlet.Application;
import org.restlet.Restlet;
import org.restlet.routing.Router;
import org.serviio.ui.resources.server.ActionsServerResource;
import org.serviio.ui.resources.server.ApplicationServerResource;
import org.serviio.ui.resources.server.ConsoleSettingsServerResource;
import org.serviio.ui.resources.server.LibraryStatusServerResource;
import org.serviio.ui.resources.server.LicenseUploadServerResource;
import org.serviio.ui.resources.server.MetadataServerResource;
import org.serviio.ui.resources.server.OnlinePluginsServerResource;
import org.serviio.ui.resources.server.PingServerResource;
import org.serviio.ui.resources.server.PresentationServerResource;
import org.serviio.ui.resources.server.ReferenceDataServerResource;
import org.serviio.ui.resources.server.RemoteAccessServerResource;
import org.serviio.ui.resources.server.RepositoryServerResource;
import org.serviio.ui.resources.server.ServiceStatusServerResource;
import org.serviio.ui.resources.server.StatusServerResource;
import org.serviio.ui.resources.server.TranscodingServerResource;

public class ApiRestletApplication : Application
{
  public static final String APP_CONTEXT = "/rest";

  public Restlet createInboundRoot()
  {
    Router router = new Router(getContext());

    router.attach("/metadata", MetadataServerResource.class);
    router.attach("/transcoding", TranscodingServerResource.class);
    router.attach("/refdata/{name}", ReferenceDataServerResource.class);
    router.attach("/action", ActionsServerResource.class);
    router.attach("/library-status", LibraryStatusServerResource.class);
    router.attach("/repository", RepositoryServerResource.class);
    router.attach("/status", StatusServerResource.class);
    router.attach("/service-status", ServiceStatusServerResource.class);
    router.attach("/application", ApplicationServerResource.class);
    router.attach("/presentation", PresentationServerResource.class);
    router.attach("/console-settings", ConsoleSettingsServerResource.class);
    router.attach("/remote-access", RemoteAccessServerResource.class);
    router.attach("/license-upload", LicenseUploadServerResource.class);
    router.attach("/plugins", OnlinePluginsServerResource.class);
    router.attach("/ping", PingServerResource.class);

    return router;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.ui.ApiRestletApplication
 * JD-Core Version:    0.6.2
 */