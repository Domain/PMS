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
		return cast(String[])[ "upnp:class" ];
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
		return cast(String[])[ "@id" ];
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
		return cast(String[])[ "@parentID" ];
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
		return cast(String[])[ "dc:title" ];
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
		return cast(String[])[ "dc:creator" ];
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
		return cast(String[])[ "upnp:genre" ];
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
		return cast(String[])[ "@childCount" ];
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
		return cast(String[])[ "@refID" ];
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
		return cast(String[])[ "dc:description" ];
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
		return cast(String[])[ "upnp:longDescription" ];
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
		return cast(String[])[ "dc:language" ];
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
		return cast(String[])[ "dc:publisher" ];
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
		return cast(String[])[ "upnp:actor" ];
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
		return cast(String[])[ "upnp:director" ];
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
		return cast(String[])[ "upnp:producer" ];
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
		return cast(String[])[ "upnp:artist" ];
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
		return cast(String[])[ "dc:rights" ];
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
		return cast(String[])[ "upnp:rating" ];
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
		return cast(String[])[ "@restricted" ];
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
		return cast(String[])[ "@searchable" ];
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
		return cast(String[])[ "upnp:album" ];
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
		return cast(String[])[ "res" ];
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
		return cast(String[])[ "res@size" ];
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
		return cast(String[])[ "res@duration" ];
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
		return cast(String[])[ "res@bitrate" ];
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
		return cast(String[])[ "res@protocolInfo" ];
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
		return cast(String[])[ "res@nrAudioChannels" ];
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
		return cast(String[])[ "res@sampleFrequency" ];
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
		return cast(String[])[ "res@resolution" ];
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
		return cast(String[])[ "res@colorDepth" ];
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
		return cast(String[])[ "upnp:originalTrackNumber" ];
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
		return cast(String[])[ "dc:date" ];
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
		return cast(String[])[ "upnp:albumArtURI" ];
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
		return cast(String[])[ "upnp:icon" ];
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
		return cast(String[])[ "sec:CaptionInfoEx", "res@pv:subtitleFileUri" ];
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
		return cast(String[])[ "sec:dcmInfo" ];
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
		return cast(String[])[ "av:mediaClass" ];
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