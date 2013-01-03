module org.serviio.update.dao.DBLogDAO;

import org.serviio.db.dao.PersistenceException;

public abstract interface DBLogDAO
{
  public abstract bool isScriptPresent(String paramString)
    throws PersistenceException;
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.update.dao.DBLogDAO
 * JD-Core Version:    0.6.2
 */