module org.serviio.config.PropertiesFileConfigStorage;

import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Properties;

public class PropertiesFileConfigStorage
  : ConfigStorage
{
  private Properties properties;

  public this()
  {
    properties = new Properties();
    try {
      properties.load(PropertiesFileConfigStorage.class.getResourceAsStream("/configuration.properties"));
    }
    catch (Exception e)
    {
    }
  }

  public Map<String, String> readAllConfigurationValues()
  {
    Map<String, String> values = new HashMap<String, String>();
    for (Entry<?, ?> value : properties.entrySet()) {
      values.put(value.getKey().toString(), value.getValue().toString());
    }
    return values;
  }

  public void storeValue(String name, String value)
  {
    properties.put(name, value);
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.config.PropertiesFileConfigStorage
 * JD-Core Version:    0.6.2
 */