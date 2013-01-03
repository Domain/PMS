module org.serviio.library.online.feed.ITunesRssFeedEntryParser;

import com.sun.syndication.feed.synd.SyndEntry;
import java.util.Collections;
import org.serviio.library.local.metadata.ImageDescriptor;
import org.serviio.library.online.feed.module.itunes.ITunesRssModule;
import org.serviio.library.online.feed.module.itunes.Image;
import org.serviio.library.online.metadata.FeedItem;
import org.serviio.util.ObjectValidator;

public class ITunesRssFeedEntryParser
  : FeedEntryParser
{
  public void parseFeedEntry(SyndEntry entry, FeedItem item)
  {
    ITunesRssModule module = cast(ITunesRssModule)entry.getModule("http://itunes.apple.com/rss");
    if (module !is null)
    {
      if (ObjectValidator.isNotEmpty(module.getArtist())) {
        item.setAuthor(module.getArtist());
      }

      if (module.getReleaseDate() !is null) {
        item.setDate(module.getReleaseDate());
      }

      if (module.getDuration() !is null) {
        item.getTechnicalMD().setDuration(new Long(module.getDuration().intValue() / 1000));
      }

      if ((module.getImages() !is null) && (module.getImages().size() > 0)) {
        Collections.sort(module.getImages());

        Image selectedThumbnail = cast(Image)module.getImages().get(module.getImages().size() - 1);

        ImageDescriptor thumbnail = new ImageDescriptor(selectedThumbnail.getUrl());
        thumbnail.setWidth(selectedThumbnail.getWidth());
        thumbnail.setHeight(selectedThumbnail.getHeight());
        item.setThumbnail(thumbnail);
      }
    }
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.library.online.feed.ITunesRssFeedEntryParser
 * JD-Core Version:    0.6.2
 */