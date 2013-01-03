module org.serviio.external.AbstractExecutableWrapper;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractExecutableWrapper
{
  private static final Logger log = LoggerFactory.getLogger(AbstractExecutableWrapper.class_);

  protected static void executeSynchronously(ProcessExecutor executor)
  {
    executor.start();
    try {
      executor.join();
    } catch (InterruptedException e) {
      log.debug_("Interrupted executable invocation, killing the process");
      executor.stopProcess(false);
    }
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.external.AbstractExecutableWrapper
 * JD-Core Version:    0.6.2
 */