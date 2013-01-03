module org.serviio.upnp.protocol.http.transport.RequestedResourceDescriptor;

import java.util.regex.Pattern;
import org.serviio.profile.DeliveryQuality.QualityType;
import org.serviio.upnp.service.contentdirectory.classes.Resource.ResourceType;
import org.serviio.upnp.webserver.AbstractRequestHandler;
import org.serviio.util.StringUtils;

public class RequestedResourceDescriptor
{
  private static final Pattern URL_EXTENSION_REMOVAL_PATTERN = Pattern.compile("(?<=/[a-zA-Z]{0,25})\\.[a-zA-Z]+");
  private Long resourceId;
  private ResourceType resourceType;
  private String targetProfileName;
  private Integer protocolInfoIndex;
  private QualityType quality;

  public this(String requestUri)
    {
    try
    {
      String[] requestFields = AbstractRequestHandler.getRequestPathFields(requestUri, "/resource", URL_EXTENSION_REMOVAL_PATTERN);

      resourceId = new Long(requestFields[0]);
      String resourceTypeParam = requestFields[1];
      targetProfileName = null;
      resourceType = ResourceType.valueOf(StringUtils.localeSafeToUppercase(resourceTypeParam));
      protocolInfoIndex = null;
      if (requestFields.length > 2)
      {
        String[] protocolFields = requestFields[2].split("\\-");
        targetProfileName = protocolFields[0];
        protocolInfoIndex = Integer.valueOf(Integer.parseInt(protocolFields[1].trim()));
        quality = QualityType.valueOf(requestFields[3]);
      }
    } catch (Exception e) {
      throw new InvalidResourceRequestException(String.format("Invalid incoming request: %s", new Object[] { requestUri }), e);
    }
  }

  public Long getResourceId()
  {
    return resourceId;
  }

  public ResourceType getResourceType() {
    return resourceType;
  }

  public String getTargetProfileName() {
    return targetProfileName;
  }

  public Integer getProtocolInfoIndex() {
    return protocolInfoIndex;
  }

  public QualityType getQuality() {
    return quality;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.upnp.protocol.http.transport.RequestedResourceDescriptor
 * JD-Core Version:    0.6.2
 */