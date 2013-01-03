module org.serviio.library.local.H264LevelType;

import java.util.Map;

public enum H264LevelType
{
  H, RF;

  private static EnumMapConverter!(H264LevelType) converter = new EnumMapConverter!(H264LevelType)()
  {
    protected H264LevelType enumValue(String name) {
      return H264LevelType.valueOf(name);
    }
  };

  public static Map!(H264LevelType, String) parseFromString(String identifiersCSV)
  {
    return converter.convert(identifiersCSV);
  }

  public static String parseToString(Map!(H264LevelType, String) identifiers) {
    return converter.parseToString(identifiers);
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.library.local.H264LevelType
 * JD-Core Version:    0.6.2
 */