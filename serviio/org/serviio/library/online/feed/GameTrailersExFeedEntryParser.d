module org.serviio.library.online.feed.GameTrailersExFeedEntryParser;

import com.sun.syndication.feed.synd.SyndEntry;
import java.net.MalformedURLException;
import java.net.URL;
import org.serviio.library.local.metadata.ImageDescriptor;
import org.serviio.library.online.feed.module.gametrailers.GameTrailersExModule;
import org.serviio.library.online.metadata.FeedItem;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class GameTrailersExFeedEntryParser
  : FeedEntryParser
{
  private static final Logger log = LoggerFactory.getLogger(GameTrailersExFeedEntryParser.class);

  public void parseFeedEntry(SyndEntry entry, FeedItem item)
  {
    GameTrailersExModule module = cast(GameTrailersExModule)entry.getModule("http://www.gametrailers.com/rssexplained.php");
    if (module !is null)
    {
      if (module.getThumbnailUrl() !is null) {
        try {
          ImageDescriptor thumbnail = new ImageDescriptor(new URL(module.getThumbnailUrl()));
          item.setThumbnail(thumbnail);
        } catch (MalformedURLException e) {
          log.debug_(String.format("Invalid thumbnail URL: %s. Message: %s", new Object[] { module.getThumbnailUrl(), e.getMessage() }));
        }
      }

      if (module.getFileSize() !is null)
        item.getTechnicalMD().setFileSize(module.getFileSize());
    }
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.library.online.feed.GameTrailersExFeedEntryParser
 * JD-Core Version:    0.6.2
 */