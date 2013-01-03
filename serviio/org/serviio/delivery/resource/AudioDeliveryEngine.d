module org.serviio.delivery.resource.AudioDeliveryEngine;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import org.serviio.delivery.AudioMediaInfo;
import org.serviio.delivery.resource.transcode.AbstractTranscodingDeliveryEngine;
import org.serviio.delivery.resource.transcode.AudioTranscodingDefinition;
import org.serviio.delivery.resource.transcode.AudioTranscodingMatch;
import org.serviio.delivery.resource.transcode.TranscodingDefinition;
import org.serviio.dlna.AudioContainer;
import org.serviio.dlna.MediaFormatProfile;
import org.serviio.dlna.MediaFormatProfileResolver;
import org.serviio.dlna.UnsupportedDLNAMediaFileFormatException;
import org.serviio.external.FFMPEGWrapper;
import org.serviio.library.entities.MusicTrack;
import org.serviio.profile.DeliveryQuality.QualityType;
import org.serviio.profile.Profile;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AudioDeliveryEngine : AbstractTranscodingDeliveryEngine!(AudioMediaInfo, MusicTrack)
{
  private static AudioDeliveryEngine instance;
  private static final Logger log = LoggerFactory.getLogger(AudioDeliveryEngine.class_);

  public static AudioDeliveryEngine getInstance()
  {
    if (instance is null) {
      instance = new AudioDeliveryEngine();
    }
    return instance;
  }

  protected LinkedHashMap!(QualityType, List!(AudioMediaInfo)) retrieveOriginalMediaInfo(MusicTrack mediaItem, Profile rendererProfile)
    {
    List!(MediaFormatProfile) fileProfiles = MediaFormatProfileResolver.resolve(mediaItem);
    LinkedHashMap!(QualityType, List!(AudioMediaInfo)) result = new LinkedHashMap!(QualityType, List!(AudioMediaInfo))();
    List!(AudioMediaInfo) mediaInfos = new ArrayList!(AudioMediaInfo)();

    for (MediaFormatProfile fileProfile : fileProfiles) {
      mediaInfos.add(new AudioMediaInfo(mediaItem.getId(), fileProfile, mediaItem.getFileSize(), false, mediaItem.isLive(), mediaItem.getDuration(), rendererProfile.getMimeType(fileProfile), mediaItem.getChannels(), mediaItem.getSampleFrequency(), mediaItem.getBitrate(), QualityType.ORIGINAL));
    }

    result.put(QualityType.ORIGINAL, mediaInfos);
    return result;
  }

  protected LinkedHashMap!(QualityType, List!(AudioMediaInfo)) retrieveTranscodedMediaInfo(MusicTrack mediaItem, Profile rendererProfile, Long fileSize)
  {
    LinkedHashMap!(QualityType, List!(AudioMediaInfo)) transcodedMI = new LinkedHashMap!(QualityType, List!(AudioMediaInfo))();
    Map!(QualityType, TranscodingDefinition) trDefs = getMatchingTranscodingDefinitions(mediaItem, rendererProfile);
    if (trDefs.size() > 0) {
      for (Entry!(QualityType, TranscodingDefinition) trDefEntry : trDefs.entrySet()) {
        QualityType qualityType = cast(QualityType)trDefEntry.getKey();
        AudioTranscodingDefinition trDef = cast(AudioTranscodingDefinition)trDefEntry.getValue();

        Integer targetSamplerate = FFMPEGWrapper.getAudioFrequency(trDef, mediaItem.getSampleFrequency(), trDef.getTargetContainer() == AudioContainer.LPCM);
        Integer targetBitrate = FFMPEGWrapper.getAudioBitrate(mediaItem.getBitrate(), trDef);
        Integer targetChannels = FFMPEGWrapper.getAudioChannelNumber(mediaItem.getChannels(), null, true, false);
        try
        {
          MediaFormatProfile transcodedProfile = MediaFormatProfileResolver.resolveAudioFormat(mediaItem.getFileName(), trDef.getTargetContainer(), targetBitrate, targetSamplerate, targetChannels);

          log.debug_(String.format("Found Format profile for transcoded file %s: %s", cast(Object[])[ mediaItem.getFileName(), transcodedProfile ]));

          transcodedMI.put(qualityType, Collections.singletonList(new AudioMediaInfo(mediaItem.getId(), transcodedProfile, fileSize, true, mediaItem.isLive(), mediaItem.getDuration(), rendererProfile.getMimeType(transcodedProfile), targetChannels, targetSamplerate, targetBitrate, qualityType)));
        }
        catch (UnsupportedDLNAMediaFileFormatException e) {
          log.warn(String.format("Cannot get media info for transcoded file %s: %s", cast(Object[])[ mediaItem.getFileName(), e.getMessage() ]));
        }
      }
      return transcodedMI;
    }
    log.warn(String.format("Cannot find matching transcoding definition for file %s", cast(Object[])[ mediaItem.getFileName() ]));
    return new LinkedHashMap!(QualityType, List!(AudioMediaInfo))();
  }

  protected TranscodingDefinition getMatchingTranscodingDefinition(List!(TranscodingDefinition) tDefs, MusicTrack mediaItem)
  {
    Iterator!(TranscodingDefinition) i$;
    if ((tDefs !is null) && (tDefs.size() > 0))
      for (i$ = tDefs.iterator(); i$.hasNext(); ) { TranscodingDefinition tDef = cast(TranscodingDefinition)i$.next();
        List!(AudioTranscodingMatch) matches = ( cast(AudioTranscodingDefinition)tDef).getMatches();
        for (AudioTranscodingMatch match : matches)
          if (match.matches(mediaItem.getContainer(), getOnlineContentType(mediaItem)))
            return (AudioTranscodingDefinition)tDef;
      }
    return null;
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.delivery.resource.AudioDeliveryEngine
 * JD-Core Version:    0.6.2
 */