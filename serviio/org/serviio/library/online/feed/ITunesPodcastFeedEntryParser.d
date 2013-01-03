module org.serviio.library.online.feed.ITunesPodcastFeedEntryParser;

import com.sun.syndication.feed.module.itunes.EntryInformation;
import com.sun.syndication.feed.synd.SyndEntry;
import org.serviio.library.online.metadata.FeedItem;
import org.serviio.util.ObjectValidator;

public class ITunesPodcastFeedEntryParser
  : FeedEntryParser
{
  public void parseFeedEntry(SyndEntry entry, FeedItem item)
  {
    EntryInformation module = cast(EntryInformation)entry.getModule("http://www.itunes.com/dtds/podcast-1.0.dtd");
    if (module !is null)
    {
      if (ObjectValidator.isNotEmpty(module.getAuthor())) {
        item.setAuthor(module.getAuthor());
      }
      if ((item.getTechnicalMD().getDuration() is null) && (module.getDuration() !is null))
        item.getTechnicalMD().setDuration(Long.valueOf(module.getDuration().getMilliseconds() / 1000L));
    }
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.library.online.feed.ITunesPodcastFeedEntryParser
 * JD-Core Version:    0.6.2
 */