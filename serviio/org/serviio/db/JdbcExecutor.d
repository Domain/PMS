module org.serviio.db.JdbcExecutor;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.List;
import org.serviio.util.JdbcUtils;

public abstract class JdbcExecutor<T>
{
  private static final List<String> lockErrorCodes = Arrays.asList(new String[] { "40XL1", "40XL2", "40001" });

  public void executeUpdate() {
    Connection con = null;
    PreparedStatement ps = null;
    try {
      con = DatabaseManager.getConnection();
      ps = processStatement(con);
    } catch (SQLException e) {
      if (lockErrorCodes.contains(e.getSQLState()))
      {
        ps = processStatement(con);
      }
      else throw e; 
    }
    finally
    {
      JdbcUtils.closeStatement(ps);
      DatabaseManager.releaseConnection(con);
    }
  }

  protected abstract PreparedStatement processStatement(Connection paramConnection)
    throws SQLException;
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.db.JdbcExecutor
 * JD-Core Version:    0.6.2
 */