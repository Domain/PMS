module org.serviio.library.dao.MetadataExtractorConfigDAO;

import java.util.List;
import org.serviio.db.dao.InvalidArgumentException;
import org.serviio.db.dao.PersistenceException;
import org.serviio.library.entities.MetadataExtractorConfig;
import org.serviio.library.metadata.MediaFileType;

public abstract interface MetadataExtractorConfigDAO
{
  public abstract long create(MetadataExtractorConfig paramMetadataExtractorConfig)
    throws InvalidArgumentException, PersistenceException;

  public abstract void delete(Long paramLong)
    throws PersistenceException;

  public abstract List!(MetadataExtractorConfig) retrieveByMediaFileType(MediaFileType paramMediaFileType)
    throws PersistenceException;
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.library.dao.MetadataExtractorConfigDAO
 * JD-Core Version:    0.6.2
 */