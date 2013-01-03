module org.serviio.ui.representation.ApplicationRepresentation;

import org.serviio.licensing.LicensingManager.ServiioEdition;

public class ApplicationRepresentation
{
  private String updateVersionAvailable;
  private String version;
  private ServiioEdition edition;
  private LicenseRepresentation license;

  public String getUpdateVersionAvailable()
  {
    return updateVersionAvailable;
  }

  public void setUpdateVersionAvailable(String updateVersionAvailable) {
    this.updateVersionAvailable = updateVersionAvailable;
  }

  public String getVersion() {
    return version;
  }

  public void setVersion(String version) {
    this.version = version;
  }

  public ServiioEdition getEdition() {
    return edition;
  }

  public void setEdition(ServiioEdition edition) {
    this.edition = edition;
  }

  public LicenseRepresentation getLicense() {
    return license;
  }

  public void setLicense(LicenseRepresentation license) {
    this.license = license;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.ui.representation.ApplicationRepresentation
 * JD-Core Version:    0.6.2
 */