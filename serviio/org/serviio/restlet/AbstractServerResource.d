module org.serviio.restlet.AbstractServerResource;

import org.restlet.data.Status;
import org.restlet.resource.ServerResource;
import org.serviio.upnp.Device;
import org.serviio.upnp.service.contentdirectory.ContentDirectory;

public abstract class AbstractServerResource : ServerResource
{
  protected ResultRepresentation responseOk()
  {
    return responseOk(0);
  }

  protected ResultRepresentation responseOk(int errorCode) {
    setStatus(Status.SUCCESS_OK);
    return new ResultRepresentation(Integer.valueOf(errorCode), Status.SUCCESS_OK.getCode(), null);
  }

  protected ContentDirectory getCDS() {
    return (ContentDirectory)Device.getInstance().getServiceById("urn:upnp-org:serviceId:ContentDirectory");
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.restlet.AbstractServerResource
 * JD-Core Version:    0.6.2
 */