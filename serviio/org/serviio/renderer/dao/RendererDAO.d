module org.serviio.renderer.dao.RendererDAO;

import java.util.List;
import org.serviio.db.dao.InvalidArgumentException;
import org.serviio.db.dao.PersistenceException;
import org.serviio.renderer.entities.Renderer;

public abstract interface RendererDAO
{
  public abstract void create(Renderer paramRenderer)
    throws InvalidArgumentException, PersistenceException;

  public abstract Renderer read(String paramString)
    throws PersistenceException;

  public abstract void update(Renderer paramRenderer)
    throws InvalidArgumentException, PersistenceException;

  public abstract void delete(String paramString)
    throws PersistenceException;

  public abstract List<Renderer> findByIPAddress(String paramString)
    throws PersistenceException;

  public abstract List<Renderer> findAll()
    throws PersistenceException;
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.renderer.dao.RendererDAO
 * JD-Core Version:    0.6.2
 */