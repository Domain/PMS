module org.serviio.db.dao.GenericDAO;

public abstract interface GenericDAO<T>
{
  public abstract long create(T paramT)
    throws InvalidArgumentException, PersistenceException;

  public abstract T read(Long paramLong)
    throws PersistenceException;

  public abstract void update(T paramT)
    throws InvalidArgumentException, PersistenceException;

  public abstract void delete(Long paramLong)
    throws PersistenceException;
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.db.dao.GenericDAO
 * JD-Core Version:    0.6.2
 */