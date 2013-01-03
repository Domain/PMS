module org.serviio.upnp.protocol.TemplateApplicator;

import freemarker.template.Configuration;
import freemarker.template.DefaultObjectWrapper;
import freemarker.template.Template;
import freemarker.template.TemplateException;
import java.io.IOException;
import java.io.StringWriter;
import java.io.Writer;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class TemplateApplicator
{
  private static final Logger log = LoggerFactory.getLogger(TemplateApplicator.class);

  private static Configuration cfg = new Configuration();

  public static String applyTemplate(String templateName, Map!(String, Object) parameters)
  {
    try
    {
      Template temp = cfg.getTemplate(templateName);
      Writer out = new StringWriter();
      temp.process(parameters, out);
      out.flush();
      return out.toString();
    }
    catch (IOException e) {
      log.error(String.format("Cannot find template %s", cast(Object[])[ templateName ]), e);
      return null;
    }
    catch (TemplateException e) {
      log.error(String.format("Error processing template %s: %s", cast(Object[])[ templateName, e.getMessage() ]), e);
    }return null;
  }

  static
  {
    try
    {
      cfg.setClassForTemplateLoading(TemplateApplicator.class, "/");

      cfg.setObjectWrapper(new DefaultObjectWrapper());
      cfg.setOutputEncoding("UTF-8");
      cfg.setURLEscapingCharset(null);
    } catch (Exception e) {
      log.error("Cannot initialize Freemarker engine", e);
    }
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.upnp.protocol.TemplateApplicator
 * JD-Core Version:    0.6.2
 */