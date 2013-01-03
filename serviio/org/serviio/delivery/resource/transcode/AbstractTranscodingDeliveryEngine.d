module org.serviio.delivery.resource.transcode.AbstractTranscodingDeliveryEngine;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.serviio.config.Configuration;
import org.serviio.delivery.Client;
import org.serviio.delivery.DeliveryContainer;
import org.serviio.delivery.DeliveryListener;
import org.serviio.delivery.MediaFormatProfileResource;
import org.serviio.delivery.StreamDeliveryContainer;
import org.serviio.delivery.resource.AbstractDeliveryEngine;
import org.serviio.dlna.MediaFormatProfile;
import org.serviio.dlna.UnsupportedDLNAMediaFileFormatException;
import org.serviio.library.entities.MediaItem;
import org.serviio.profile.DeliveryQuality.QualityType;
import org.serviio.profile.OnlineContentType;
import org.serviio.profile.Profile;
import org.serviio.util.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractTranscodingDeliveryEngine<RI : MediaFormatProfileResource, MI : MediaItem> : AbstractDeliveryEngine<RI, MI>
  : DeliveryListener
{
  private static final String TRANSCODING_SUBFOLDER_NAME = "Serviio";
  private static final String TRANSCODED_FILE_EXTENSION = ".stf";
  private static Map<Client, TranscodingJobListener> transcodeJobs = Collections.synchronizedMap(new HashMap<Client, TranscodingJobListener>());
  private static TranscodingDeliveryStrategy<File> fileBasedStrategy = new FileBasedTranscodingDeliveryStrategy();
  private static TranscodingDeliveryStrategy<OutputStream> streamBasedStrategy = new StreamBasedTranscodingDeliveryStrategy();

  private static final Logger log = LoggerFactory.getLogger(AbstractTranscodingDeliveryEngine.class);

  public static void cleanupTranscodingEngine()
  {
    log.info("Cleaning transcode engine and its data");
    for (TranscodingJobListener listener : transcodeJobs.values())
    {
      listener.releaseResources();
    }

    deleteTranscodeFiles();
  }

  public static File getTranscodingFolder()
  {
    File f = new File(Configuration.getTranscodingFolder(), TRANSCODING_SUBFOLDER_NAME);
    return f;
  }

  public void deliveryComplete(Client client)
  {
    synchronized (transcodeJobs) {
      transcodeJobs.remove(client);
    }
  }

  protected DeliveryContainer retrieveTranscodedResource(MI mediaItem, MediaFormatProfile selectedVersion, QualityType selectedQuality, Double timeOffsetInSeconds, Double durationInSeconds, Client client)
    {
    Map<QualityType, TranscodingDefinition> trDefs = getMatchingTranscodingDefinitions(mediaItem, client.getRendererProfile());
    TranscodingDefinition trDef = cast(TranscodingDefinition)trDefs.get(selectedQuality);
    if (trDef !is null) {
      String transcodingIdentifier = null;
      if (timeOffsetInSeconds !is null) {
        transcodingIdentifier = String.format("transcoding-temp-%s-%s-%s-%s-%s%s", new Object[] { mediaItem.getId(), client.getRendererProfile().getId(), selectedQuality.toString(), timeOffsetInSeconds, Double.valueOf(durationInSeconds !is null ? durationInSeconds.doubleValue() : 0.0D), TRANSCODED_FILE_EXTENSION });
      }
      else {
        transcodingIdentifier = String.format("transcoding-temp-%s-%s-%s%s", new Object[] { mediaItem.getId(), client.getRendererProfile().getId(), selectedQuality.toString(), TRANSCODED_FILE_EXTENSION });
      }

      TranscodingJobListener jobListener = startTranscodeJob(mediaItem, transcodingIdentifier, timeOffsetInSeconds, durationInSeconds, client, trDef);

      StreamDescriptor stream = getDeliveryStrategy(mediaItem).createInputStream(jobListener, client);
      LinkedHashMap<QualityType, List<RI>> transcodedMediaInfos = retrieveTranscodedMediaInfo(mediaItem, client.getRendererProfile(), stream.getFileSize());
      MediaFormatProfileResource transcodedMediaInfo = findMediaInfoForFileProfile((Collection<RI>)transcodedMediaInfos.get(selectedQuality), selectedVersion);
      return new StreamDeliveryContainer(new BufferedInputStream(stream.getStream(), 65536), transcodedMediaInfo, jobListener);
    }
    throw new IOException(String.format("Cannot find transcoding definition for %s quality", new Object[] { selectedQuality.toString() }));
  }

  protected RI retrieveTranscodedMediaInfoForVersion(MI mediaItem, MediaFormatProfile selectedVersion, QualityType selectedQuality, Profile rendererProfile)
    {
    log.debug_(String.format("Getting media info for transcoded version of file %s", new Object[] { mediaItem.getFileName() }));
    LinkedHashMap<QualityType, List<RI>> mediaInfos = retrieveTranscodedMediaInfo(mediaItem, rendererProfile, null);
    return findMediaInfoForFileProfile((Collection<RI>)mediaInfos.get(selectedQuality), selectedVersion);
  }

  protected bool fileCanBeTranscoded(MI mediaItem, Profile rendererProfile)
  {
    if (((mediaItem.isLocalMedia()) && ((Configuration.isTranscodingEnabled()) || (rendererProfile.isAlwaysEnableTranscoding())) && (rendererProfile.hasAnyTranscodingDefinitions())) || ((!mediaItem.isLocalMedia()) && (rendererProfile.hasAnyOnlineTranscodingDefinitions())))
    {
      if (getMatchingTranscodingDefinitions(mediaItem, rendererProfile).size() > 0)
      {
        return true;
      }
    }
    return false;
  }

  protected bool fileWillBeTranscoded(MI mediaItem, MediaFormatProfile selectedVersion, QualityType selectedQuality, Profile rendererProfile)
    {
    return (fileCanBeTranscoded(mediaItem, rendererProfile)) && (getMatchingTranscodingDefinitions(mediaItem, rendererProfile).get(selectedQuality) !is null);
  }

  protected OnlineContentType getOnlineContentType(MediaItem mediaItem) {
    if (mediaItem.isLocalMedia()) {
      return OnlineContentType.ANY;
    }
    if (mediaItem.isLive()) {
      return OnlineContentType.LIVE;
    }
    return OnlineContentType.VOD;
  }

  private void prepareClientStream(Client client, String transcodingIdentifier, TranscodingDefinition trDef)
  {
    if (transcodeJobs.containsKey(client)) {
      TranscodingJobListener existingJobListener = cast(TranscodingJobListener)transcodeJobs.get(client);

      bool closeStream = false;

      if (trDef.getTranscodingConfiguration().isKeepStreamOpen()) {
        if ((existingJobListener !is null) && (!existingJobListener.getTranscodingIdentifier().equals(transcodingIdentifier)))
        {
          if (getCountOfListenerUsers(existingJobListener) <= 1)
          {
            log.debug_(String.format("No other client uses transcoding job of file '%s', will stop the job", new Object[] { existingJobListener.getTranscodingIdentifier() }));
            closeStream = true;
          } else {
            log.debug_(String.format("Removing the client from transcoding job of file '%s'", new Object[] { existingJobListener.getTranscodingIdentifier() }));

            existingJobListener.closeStream(client);
          }
        }
      }
      else closeStream = true;

      if (closeStream) {
        log.debug_(String.format("Stopping previous transcoding job of file '%s'", new Object[] { existingJobListener.getTranscodingIdentifier() }));

        existingJobListener.releaseResources();

        deliveryComplete(client);
      }
    }
  }

  private int getCountOfListenerUsers(TranscodingJobListener listener)
  {
    int c = 0;
    for (TranscodingJobListener l : transcodeJobs.values()) {
      if (l.getTranscodingIdentifier().equals(listener.getTranscodingIdentifier())) {
        c++;
      }
    }
    return c;
  }

  private synchronized TranscodingJobListener startTranscodeJob(MI mediaItem, String transcodingIdentifier, Double timeOffsetInSeconds, Double durationInSeconds, Client client, TranscodingDefinition trDef)
    {
    prepareClientStream(client, transcodingIdentifier, trDef);

    TranscodingJobListener newListener = null;

    Collection<TranscodingJobListener> availableListeners = findExistingJobListeners(client, mediaItem.isLive(), trDef.getTranscodingConfiguration().isKeepStreamOpen());
    for (TranscodingJobListener listener : availableListeners) {
      if (listener.getTranscodingIdentifier().equals(transcodingIdentifier))
      {
        log.debug_(String.format("A suitable transcoding job already exists, re-use it for client '%s'", new Object[] { client }));
        newListener = listener;
        break;
      }
    }

    if (newListener is null) {
      log.debug_(String.format("No suitable transcoding job exists yet, start one for client '%s'", new Object[] { client }));

      updateFeedUrl(mediaItem);

      newListener = getDeliveryStrategy(mediaItem).invokeTranscoder(transcodingIdentifier, mediaItem, timeOffsetInSeconds, durationInSeconds, trDef, client, this);
    }
    registerJob(client, newListener);
    return newListener;
  }

  private void registerJob(Client client, TranscodingJobListener jobListener) {
    synchronized (transcodeJobs) {
      transcodeJobs.put(client, jobListener);
    }
  }

  private Collection<TranscodingJobListener> findExistingJobListeners(Client client, bool liveStream, bool keepLiveStreamsOpen)
  {
    synchronized (transcodeJobs) {
      if (!liveStream)
      {
        return transcodeJobs.values();
      }
      if ((transcodeJobs.containsKey(client)) && (keepLiveStreamsOpen))
      {
        return Collections.singleton(transcodeJobs.get(client));
      }

      return Collections.emptySet();
    }
  }

  private static void deleteTranscodeFiles()
  {
    File transcodeFolder = getTranscodingFolder();
    if ((transcodeFolder.exists()) && (transcodeFolder.isDirectory())) {
      log.debug_(String.format("Deleting temporary transcoded files from: %s", new Object[] { transcodeFolder }));
      File[] transcodedFiles = transcodeFolder.listFiles(new class() FilenameFilter {
        public bool accept(File dir, String name)
        {
          if (StringUtils.localeSafeToLowercase(name).endsWith(TRANSCODED_FILE_EXTENSION)) {
            return true;
          }
          return false;
        }
      });
      for (File f : transcodedFiles) {
        bool result = f.delete();
        log.debug_(String.format("Deleted file %s: %s", new Object[] { f, Boolean.valueOf(result) }));
      }
    }
  }

  private TranscodingDeliveryStrategy<?> getDeliveryStrategy(MI mediaItem) {
    if (mediaItem.isLive()) {
      return streamBasedStrategy;
    }
    return fileBasedStrategy;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.delivery.resource.transcode.AbstractTranscodingDeliveryEngine
 * JD-Core Version:    0.6.2
 */