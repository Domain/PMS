module org.serviio.library.local.metadata.extractor.ExtractorType;

import org.serviio.library.local.metadata.extractor.embedded.EmbeddedMetadataExtractor;
import org.serviio.library.local.metadata.extractor.video.OnlineVideoSourcesMetadataExtractor;

public enum ExtractorType
{
  EMBEDDED {
	override
	public MetadataExtractor getExtractorInstance()
	{
		return new EmbeddedMetadataExtractor();
	}

	override
	public int getDefaultPriority()
	{
		return 0;
	}

	override
	public bool isDescriptiveMetadataExtractor()
	{
		return false;
	}
}, 

  COVER_IMAGE_IN_FOLDER {
	override
	public MetadataExtractor getExtractorInstance()
	{
		return new CoverImageInFolderExtractor();
	}

	override
	public int getDefaultPriority()
	{
		return 10;
	}

	override
	public bool isDescriptiveMetadataExtractor()
	{
		return false;
	}
}, 

  ONLINE_VIDEO_SOURCES {
	override
	public MetadataExtractor getExtractorInstance()
	{
		return new OnlineVideoSourcesMetadataExtractor();
	}

	override
	public int getDefaultPriority()
	{
		return 1;
	}

	override
	public bool isDescriptiveMetadataExtractor()
	{
		return true;
	}
}, 

  SWISSCENTER {
	override
	public MetadataExtractor getExtractorInstance()
	{
		return new SwissCenterExtractor();
	}

	override
	public int getDefaultPriority()
	{
		return 2;
	}

	override
	public bool isDescriptiveMetadataExtractor()
	{
		return true;
	}
}, 

  XBMC {
	override
	public MetadataExtractor getExtractorInstance()
	{
		return new XBMCExtractor();
	}

	override
	public int getDefaultPriority()
	{
		return 2;
	}

	override
	public bool isDescriptiveMetadataExtractor()
	{
		return true;
	}
}, 

  MYMOVIES {
	override
	public MetadataExtractor getExtractorInstance()
	{
		return new MyMoviesExtractor();
	}

	override
	public int getDefaultPriority()
	{
		return 2;
	}

	override
	public bool isDescriptiveMetadataExtractor()
	{
		return true;
	}
};

  public abstract MetadataExtractor getExtractorInstance();

  public abstract int getDefaultPriority();

  public abstract bool isDescriptiveMetadataExtractor();
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.library.local.metadata.extractor.ExtractorType
 * JD-Core Version:    0.6.2
 */