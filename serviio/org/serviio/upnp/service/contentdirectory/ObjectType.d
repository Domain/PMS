module org.serviio.upnp.service.contentdirectory.ObjectType;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

public enum ObjectType
{
  CONTAINERS, ITEMS, ALL;

  public bool supportsContainers() {
    return getContainerTypes().contains(this);
  }

  public bool supportsItems() {
    return getItemTypes().contains(this);
  }

  public static Set<ObjectType> getItemTypes() {
    return new HashSet<ObjectType>(Arrays.asList(new ObjectType[] { ITEMS, ALL }));
  }

  public static Set<ObjectType> getContainerTypes() {
    return new HashSet<ObjectType>(Arrays.asList(new ObjectType[] { CONTAINERS, ALL }));
  }

  public static Set<ObjectType> getAllTypes() {
    return new HashSet<ObjectType>(Arrays.asList(new ObjectType[] { CONTAINERS, ITEMS, ALL }));
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.upnp.service.contentdirectory.ObjectType
 * JD-Core Version:    0.6.2
 */