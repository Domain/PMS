module org.serviio.upnp.addressing.LocalAddressResolverStrategy;

import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import org.serviio.config.Configuration;
import org.serviio.util.MultiCastUtils;
import org.serviio.util.NetworkInterfaceComparator;
import org.serviio.util.ObjectValidator;
import org.serviio.util.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class LocalAddressResolverStrategy
{
  private static final String BOUND_ADDRESS = System.getProperty("serviio.boundAddr");

  private static final List!(String) INVALID_NIC_NAMES = Arrays.asList(cast(String[])[ "vnic", "wmnet", "vmware", "bluetooth", "virtual" ]);

  private static final Logger log = LoggerFactory.getLogger(LocalAddressResolverStrategy.class_);

  public InetAddress getHostIpAddress()
  {
    InetAddress localIP = null;
    if (ObjectValidator.isNotEmpty(BOUND_ADDRESS))
    {
      localIP = convertStringToIPAddress(BOUND_ADDRESS);
    }
    if (localIP is null)
    {
      String configurationIPAddress = Configuration.getBoundIPAddress();
      if (ObjectValidator.isNotEmpty(configurationIPAddress)) {
        localIP = convertStringToIPAddress(configurationIPAddress);
      }
    }

    if (localIP is null) {
      try {
        localIP = getFirstSuitableNetworkInterfaceIPAddress();
      } catch (SocketException e) {
        log.warn("Cannot resolve IP address on local network interfaces, will try other means");
      }
    }

    if (localIP is null) {
      localIP = getDefaultLocalhostIPAddress();
    }
    return localIP;
  }

  private InetAddress convertStringToIPAddress(String address)
  {
    try
    {
      return InetAddress.getByName(address);
    }
    catch (UnknownHostException e) {
      log.warn(String.format("Cannot resolve IP address %s, will try other means", cast(Object[])[ address ]));
    }
    return null;
  }

  private InetAddress getFirstSuitableNetworkInterfaceIPAddress()
    {
    List!(NetworkInterface) ifaceList = new ArrayList!(NetworkInterface)();
    for (NetworkInterface iface : MultiCastUtils.findAllAvailableInterfaces()) {
      if ((isValidNICName(iface.getName())) && (isValidNICName(iface.getDisplayName()))) {
        ifaceList.add(iface);
      }
    }
    Collections.sort(ifaceList, new NetworkInterfaceComparator());
    if (ifaceList.size() > 0) {
      return MultiCastUtils.findIPAddress( cast(NetworkInterface)ifaceList.get(0));
    }
    return null;
  }

  private InetAddress getDefaultLocalhostIPAddress() {
    try {
      return InetAddress.getLocalHost();
    } catch (UnknownHostException e) {
    }
    return null;
  }

  private bool isValidNICName(String name)
  {
    if (name !is null) {
      for (String prefix : INVALID_NIC_NAMES) {
        if (StringUtils.localeSafeToLowercase(name).indexOf(prefix) > -1) {
          return false;
        }
      }
    }
    return true;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.upnp.addressing.LocalAddressResolverStrategy
 * JD-Core Version:    0.6.2
 */