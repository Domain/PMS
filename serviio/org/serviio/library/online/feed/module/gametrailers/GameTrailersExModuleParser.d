module org.serviio.library.online.feed.module.gametrailers.GameTrailersExModuleParser;

import com.sun.syndication.feed.module.Module;
import com.sun.syndication.io.ModuleParser;
import org.jdom.Element;
import org.jdom.Namespace;

public class GameTrailersExModuleParser
  : ModuleParser
{
  private static final Namespace NS = Namespace.getNamespace("http://www.gametrailers.com/rssexplained.php");

  public String getNamespaceUri()
  {
    return "http://www.gametrailers.com/rssexplained.php";
  }

  public Module parse(Element element)
  {
    GameTrailersExModule module = new GameTrailersExModuleImpl();
    Element fileType = element.getChild("fileType", NS);
    Element image = element.getChild("image", NS);

    if (image !is null) {
      module.setThumbnailUrl(image.getTextTrim());
    }
    if (fileType !is null) {
      Element fileSize = fileType.getChild("fileSize");
      if (fileSize !is null) {
        module.setFileSize(new Long(fileSize.getTextTrim()));
      }
    }
    return module;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.library.online.feed.module.gametrailers.GameTrailersExModuleParser
 * JD-Core Version:    0.6.2
 */