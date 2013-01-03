module org.serviio.upnp.service.contentdirectory.command.Command;

import org.serviio.upnp.service.contentdirectory.BrowseItemsHolder;
import org.serviio.upnp.service.contentdirectory.classes.DirectoryObject;

public abstract interface Command<T : DirectoryObject>
{
  public abstract BrowseItemsHolder!(T) retrieveItemList()
    throws CommandExecutionException;

  public abstract int retrieveItemCount()
    throws CommandExecutionException;

  public abstract T retrieveItem()
    throws CommandExecutionException;
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.upnp.service.contentdirectory.command.Command
 * JD-Core Version:    0.6.2
 */