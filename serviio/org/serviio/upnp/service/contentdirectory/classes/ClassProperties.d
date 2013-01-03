module org.serviio.upnp.service.contentdirectory.classes.ClassProperties;

public enum ClassProperties
{
  OBJECT_CLASS {
	override
	public String getAttributeName()
	{
		return "objectClass";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "upnp:class" };
	}
}, 

  ID {
	override
	public String getAttributeName()
	{
		return "id";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "@id" };
	}
}, 

  PARENT_ID {
	override
	public String getAttributeName()
	{
		return "parentID";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "@parentID" };
	}
}, 

  TITLE {
	override
	public String getAttributeName()
	{
		return "title";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "dc:title" };
	}
}, 

  CREATOR {
	override
	public String getAttributeName()
	{
		return "creator";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "dc:creator" };
	}
}, 

  GENRE {
	override
	public String getAttributeName()
	{
		return "genre";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "upnp:genre" };
	}
}, 

  CHILD_COUNT {
	override
	public String getAttributeName()
	{
		return "childCount";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "@childCount" };
	}
}, 

  REF_ID {
	override
	public String getAttributeName()
	{
		return "refID";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "@refID" };
	}
}, 

  DESCRIPTION {
	override
	public String getAttributeName()
	{
		return "description";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "dc:description" };
	}
}, 

  LONG_DESCRIPTION {
	override
	public String getAttributeName()
	{
		return "longDescription";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "upnp:longDescription" };
	}
}, 

  LANGUAGE {
	override
	public String getAttributeName()
	{
		return "language";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "dc:language" };
	}
}, 

  PUBLISHER {
	override
	public String getAttributeName()
	{
		return "publishers";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "dc:publisher" };
	}
}, 

  ACTOR {
	override
	public String getAttributeName()
	{
		return "actors";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "upnp:actor" };
	}
}, 

  DIRECTOR {
	override
	public String getAttributeName()
	{
		return "directors";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "upnp:director" };
	}
}, 

  PRODUCER {
	override
	public String getAttributeName()
	{
		return "producers";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "upnp:producer" };
	}
}, 

  ARTIST {
	override
	public String getAttributeName()
	{
		return "artist";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "upnp:artist" };
	}
}, 

  RIGHTS {
	override
	public String getAttributeName()
	{
		return "rights";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "dc:rights" };
	}
}, 

  RATING {
	override
	public String getAttributeName()
	{
		return "rating";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "upnp:rating" };
	}
}, 

  RESTRICTED {
	override
	public String getAttributeName()
	{
		return "restricted";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "@restricted" };
	}
}, 

  SEARCHABLE {
	override
	public String getAttributeName()
	{
		return "searchable";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "@searchable" };
	}
}, 

  ALBUM {
	override
	public String getAttributeName()
	{
		return "album";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "upnp:album" };
	}
}, 

  RESOURCE_URL {
	override
	public String getAttributeName()
	{
		return "resource.generatedURL";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "res" };
	}
}, 

  RESOURCE_SIZE {
	override
	public String getAttributeName()
	{
		return "resource.size";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "res@size" };
	}
}, 

  RESOURCE_DURATION {
	override
	public String getAttributeName()
	{
		return "resource.durationFormatted";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "res@duration" };
	}
}, 

  RESOURCE_BITRATE {
	override
	public String getAttributeName()
	{
		return "resource.bitrate";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "res@bitrate" };
	}
}, 

  RESOURCE_PROTOCOLINFO {
	override
	public String getAttributeName()
	{
		return "resource.protocolInfo";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "res@protocolInfo" };
	}
}, 

  RESOURCE_CHANNELS {
	override
	public String getAttributeName()
	{
		return "resource.nrAudioChannels";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "res@nrAudioChannels" };
	}
}, 

  RESOURCE_SAMPLE_FREQUENCY {
	override
	public String getAttributeName()
	{
		return "resource.sampleFrequency";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "res@sampleFrequency" };
	}
}, 

  RESOURCE_RESOLUTION {
	override
	public String getAttributeName()
	{
		return "resource.resolution";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "res@resolution" };
	}
}, 

  RESOURCE_COLOR_DEPTH {
	override
	public String getAttributeName()
	{
		return "resource.colorDepth";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "res@colorDepth" };
	}
}, 

  ORIGINAL_TRACK_NUMBER {
	override
	public String getAttributeName()
	{
		return "originalTrackNumber";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "upnp:originalTrackNumber" };
	}
}, 

  DATE {
	override
	public String getAttributeName()
	{
		return "date";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "dc:date" };
	}
}, 

  ALBUM_ART_URI {
	override
	public String getAttributeName()
	{
		return "albumArtURIResource.generatedURL";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "upnp:albumArtURI" };
	}
}, 

  ICON {
	override
	public String getAttributeName()
	{
		return "icon.generatedURL";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "upnp:icon" };
	}
}, 

  SUBTITLES_URL {
	override
	public String getAttributeName()
	{
		return "subtitlesUrlResource.generatedURL";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "sec:CaptionInfoEx", "res@pv:subtitleFileUri" };
	}
}, 

  DCM_INFO {
	override
	public String getAttributeName()
	{
		return "dcmInfo";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "sec:dcmInfo" };
	}
}, 

  MEDIA_CLASS {
	override
	public String getAttributeName()
	{
		return "mediaClass";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[] { "av:mediaClass" };
	}
}, 

  LIVE {
	override
	public String getAttributeName()
	{
		return "live";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[0];
	}
}, 

  ONLINE_DB_IDENTIFIERS {
	override
	public String getAttributeName()
	{
		return "onlineIdentifiers";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[0];
	}
}, 

  CONTENT_TYPE {
	override
	public String getAttributeName()
	{
		return "contentType";
	}

	override
	public String[] getPropertyFilterNames()
	{
		return new String[0];
	}
};

  public abstract String getAttributeName();

  public abstract String[] getPropertyFilterNames();

  public String getFirstPropertyXMLName()
  {
    int attributeSep = getPropertyFilterNames()[0].indexOf("@");
    if (attributeSep > -1) {
      return getPropertyFilterNames()[0].substring(attributeSep + 1);
    }
    return getPropertyFilterNames()[0];
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.upnp.service.contentdirectory.classes.ClassProperties
 * JD-Core Version:    0.6.2
 */