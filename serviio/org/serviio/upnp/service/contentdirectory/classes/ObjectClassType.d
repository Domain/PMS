module org.serviio.upnp.service.contentdirectory.classes.ObjectClassType;

public enum ObjectClassType
{
  CONTAINER {
	override
	public String getClassName()
	{
		return "object.container";
	}
}, 

  AUDIO_ITEM {
	override
	public String getClassName()
	{
		return "object.item.audioItem";
	}
}, 

  VIDEO_ITEM {
	override
	public String getClassName()
	{
		return "object.item.videoItem";
	}
}, 

  IMAGE_ITEM {
	override
	public String getClassName()
	{
		return "object.item.imageItem";
	}
}, 

  MOVIE {
	override
	public String getClassName()
	{
		return "object.item.videoItem.movie";
	}
}, 

  MUSIC_TRACK {
	override
	public String getClassName()
	{
		return "object.item.audioItem.musicTrack";
	}
}, 

  PHOTO {
	override
	public String getClassName()
	{
		return "object.item.imageItem.photo";
	}
}, 

  PLAYLIST_ITEM {
	override
	public String getClassName()
	{
		return "object.container";
	}
}, 

  PLAYLIST_CONTAINER {
	override
	public String getClassName()
	{
		return "object.container.playlistContainer";
	}
}, 

  PERSON {
	override
	public String getClassName()
	{
		return "object.container.person";
	}
}, 

  MUSIC_ARTIST {
	override
	public String getClassName()
	{
		return "object.container.person.musicArtist";
	}
}, 

  GENRE {
	override
	public String getClassName()
	{
		return "object.container.genre";
	}
}, 

  MUSIC_GENRE {
	override
	public String getClassName()
	{
		return "object.container.genre.musicGenre";
	}
}, 

  ALBUM {
	override
	public String getClassName()
	{
		return "object.container.album";
	}
}, 

  MUSIC_ALBUM {
	override
	public String getClassName()
	{
		return "object.container.album.musicAlbum";
	}
}, 

  STORAGE_FOLDER {
	override
	public String getClassName()
	{
		return "object.container.storageFolder";
	}
};

  public abstract String getClassName();
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.upnp.service.contentdirectory.classes.ObjectClassType
 * JD-Core Version:    0.6.2
 */