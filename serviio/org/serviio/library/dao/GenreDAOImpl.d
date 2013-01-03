module org.serviio.library.dao.GenreDAOImpl;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import org.serviio.db.DatabaseManager;
import org.serviio.db.JdbcExecutor;
import org.serviio.db.dao.InvalidArgumentException;
import org.serviio.db.dao.PersistenceException;
import org.serviio.library.entities.Genre;
import org.serviio.library.metadata.MediaFileType;
import org.serviio.util.JdbcUtils;
import org.serviio.util.ObjectValidator;
import org.serviio.util.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class GenreDAOImpl
  : GenreDAO
{
  private static final Logger log = LoggerFactory.getLogger(GenreDAOImpl.class);

  public long create(Genre newInstance)
    {
    if ((newInstance is null) || (ObjectValidator.isEmpty(newInstance.getName()))) {
      throw new InvalidArgumentException("Cannot create Genre. Required data is missing.");
    }
    log.debug_(String.format("Creating a new Genre (name = %s)", new Object[] { newInstance.getName() }));
    Connection con = null;
    PreparedStatement ps = null;
    try {
      con = DatabaseManager.getConnection();
      ps = con.prepareStatement("INSERT INTO genre (name) VALUES (?)", 1);

      ps.setString(1, JdbcUtils.trimToMaxLength(newInstance.getName(), 128));
      ps.executeUpdate();
      return JdbcUtils.retrieveGeneratedID(ps);
    } catch (SQLException e) {
      throw new PersistenceException(String.format("Cannot create Genre with name %s", new Object[] { newInstance.getName() }), e);
    } finally {
      JdbcUtils.closeStatement(ps);
      DatabaseManager.releaseConnection(con);
    }
  }

  public void delete(final Long id) {
    log.debug_(String.format("Deleting a Genre (id = %s)", new Object[] { id }));
    try
    {
      new JdbcExecutor<Object>()
      {
        protected PreparedStatement processStatement(Connection con) {
          PreparedStatement ps = con.prepareStatement("DELETE FROM genre WHERE id = ?");
          ps.setLong(1, id.longValue());
          ps.executeUpdate();
          return ps;
        }
      }
      .executeUpdate();
    }
    catch (SQLException e)
    {
      throw new PersistenceException(String.format("Cannot delete Genre with id = %s", new Object[] { id }), e);
    }
  }

  public Genre read(Long id) {
    log.debug_(String.format("Reading a Genre (id = %s)", new Object[] { id }));
    Connection con = null;
    PreparedStatement ps = null;
    try {
      con = DatabaseManager.getConnection();
      ps = con.prepareStatement("SELECT id, name FROM genre where id = ?");
      ps.setLong(1, id.longValue());
      ResultSet rs = ps.executeQuery();
      return mapSingleResult(rs);
    } catch (SQLException e) {
      throw new PersistenceException(String.format("Cannot read Genre with id = %s", new Object[] { id }), e);
    } finally {
      JdbcUtils.closeStatement(ps);
      DatabaseManager.releaseConnection(con);
    }
  }

  public void update(Genre transientObject) {
    throw new UnsupportedOperationException("Genre update is not supported");
  }

  public Genre findGenreByName(String name)
  {
    log.debug_(String.format("Reading a Genre (name = %s)", new Object[] { name }));
    Connection con = null;
    PreparedStatement ps = null;
    try {
      con = DatabaseManager.getConnection();
      ps = con.prepareStatement("SELECT id, name FROM genre where lower(name) = ?");
      ps.setString(1, StringUtils.localeSafeToLowercase(name));
      ResultSet rs = ps.executeQuery();
      return mapSingleResult(rs);
    } catch (SQLException e) {
      throw new PersistenceException(String.format("Cannot read Genre with name = %s", new Object[] { name }), e);
    } finally {
      JdbcUtils.closeStatement(ps);
      DatabaseManager.releaseConnection(con);
    }
  }

  public int getNumberOfMediaItems(Long genreId)
  {
    log.debug_(String.format("Getting number of media items for genre %s", new Object[] { genreId }));
    Connection con = null;
    PreparedStatement ps = null;
    try {
      con = DatabaseManager.getConnection();
      ps = con.prepareStatement("SELECT count(media_item.id) as items from media_item, genre WHERE media_item.genre_id = genre.id AND genre.id = ?");

      ps.setLong(1, genreId.longValue());

      ResultSet rs = ps.executeQuery();
      Integer count;
      if (rs.next()) {
        count = Integer.valueOf(rs.getInt("items"));
        return count.intValue();
      }
      return 0;
    }
    catch (SQLException e) {
      throw new PersistenceException(String.format("Cannot get number of media items for genre: %s ", new Object[] { genreId }), e);
    } finally {
      JdbcUtils.closeStatement(ps);
      DatabaseManager.releaseConnection(con);
    }
  }

  public List<Genre> retrieveGenres(MediaFileType fileType, int startingIndex, int requestedCount)
  {
    log.debug_(String.format("Retrieving list of genres for %s (from=%s, count=%s)", new Object[] { fileType, Integer.valueOf(startingIndex), Integer.valueOf(requestedCount) }));
    Connection con = null;
    PreparedStatement ps = null;
    try {
      con = DatabaseManager.getConnection();
      ps = con.prepareStatement("SELECT DISTINCT(genre.id) as id, genre.name as name FROM genre, media_item WHERE media_item.genre_id = genre.id AND media_item.file_type = ? ORDER BY lower(genre.name) OFFSET " + startingIndex + " ROWS FETCH FIRST " + requestedCount + " ROWS ONLY");

      ps.setString(1, fileType.toString());
      ResultSet rs = ps.executeQuery();
      return mapResultSet(rs);
    } catch (SQLException e) {
      throw new PersistenceException(String.format("Cannot read list of genres for %s", new Object[] { fileType }), e);
    } finally {
      JdbcUtils.closeStatement(ps);
      DatabaseManager.releaseConnection(con);
    }
  }

  public int getGenreCount(MediaFileType fileType)
  {
    log.debug_(String.format("Retrieving number of genres for %s", new Object[] { fileType }));
    Connection con = null;
    PreparedStatement ps = null;
    try {
      con = DatabaseManager.getConnection();
      ps = con.prepareStatement("SELECT COUNT(DISTINCT(genre.id)) as c FROM genre, media_item WHERE media_item.genre_id = genre.id AND media_item.file_type = ?");

      ps.setString(1, fileType.toString());
      ResultSet rs = ps.executeQuery();
      Integer count;
      if (rs.next()) {
        count = Integer.valueOf(rs.getInt("c"));
        return count.intValue();
      }
      return 0;
    }
    catch (SQLException e) {
      throw new PersistenceException(String.format("Cannot read number of genres for %s", new Object[] { fileType }), e);
    } finally {
      JdbcUtils.closeStatement(ps);
      DatabaseManager.releaseConnection(con);
    }
  }

  protected Genre mapSingleResult(ResultSet rs)
    {
    if (rs.next()) {
      return initGenre(rs);
    }
    return null;
  }

  protected List<Genre> mapResultSet(ResultSet rs)
    {
    List<Genre> result = new ArrayList<Genre>();
    while (rs.next()) {
      result.add(initGenre(rs));
    }
    return result;
  }

  private Genre initGenre(ResultSet rs) {
    Long id = Long.valueOf(rs.getLong("id"));
    String name = rs.getString("name");

    Genre genre = new Genre(name);
    genre.setId(id);

    return genre;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.library.dao.GenreDAOImpl
 * JD-Core Version:    0.6.2
 */