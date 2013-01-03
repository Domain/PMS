module org.serviio.dlna.MediaFormatProfile;

import java.util.Arrays;
import java.util.List;
import org.serviio.library.metadata.MediaFileType;

public enum MediaFormatProfile
{
  MP3 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.AUDIO;
	}
}, 

  WMA_BASE {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.AUDIO;
	}
}, 

  WMA_FULL {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.AUDIO;
	}
}, 

  LPCM16_44_MONO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.AUDIO;
	}
}, 

  LPCM16_44_STEREO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.AUDIO;
	}
}, 

  LPCM16_48_MONO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.AUDIO;
	}
}, 

  LPCM16_48_STEREO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.AUDIO;
	}
}, 

  AAC_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.AUDIO;
	}
}, 

  AAC_ISO_320 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.AUDIO;
	}
}, 

  AAC_ADTS {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.AUDIO;
	}
}, 

  AAC_ADTS_320 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.AUDIO;
	}
}, 

  FLAC {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.AUDIO;
	}
}, 

  OGG {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.AUDIO;
	}
}, 

  JPEG_SM {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.IMAGE;
	}
}, 

  JPEG_MED {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.IMAGE;
	}
}, 

  JPEG_LRG {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.IMAGE;
	}
}, 

  JPEG_TN {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.IMAGE;
	}
}, 

  PNG_LRG {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.IMAGE;
	}
}, 

  PNG_TN {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.IMAGE;
	}
}, 

  GIF_LRG {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.IMAGE;
	}
}, 

  RAW {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.IMAGE;
	}
}, 

  MPEG1 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG_PS_PAL {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG_PS_NTSC {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG_TS_SD_EU {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG_TS_SD_EU_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG_TS_SD_EU_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG_TS_SD_NA {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG_TS_SD_NA_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG_TS_SD_NA_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG_TS_SD_KO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG_TS_SD_KO_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG_TS_SD_KO_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG_TS_JP_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVI {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MATROSKA {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  FLV {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  DVR_MS {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  WTV {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  OGV {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_MP4_MP_SD_AAC_MULT5 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_MP4_MP_SD_MPEG1_L3 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_MP4_MP_SD_AC3 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_MP4_MP_HD_720p_AAC {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_MP4_MP_HD_1080i_AAC {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_MP4_HP_HD_AAC {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_HD_AAC_MULT5 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_HD_AAC_MULT5_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_HD_AAC_MULT5_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_HD_MPEG1_L3 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_HD_MPEG1_L3_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_HD_MPEG1_L3_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_HD_AC3 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_HD_AC3_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_HD_AC3_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_HP_HD_MPEG1_L2_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_HP_HD_MPEG1_L2_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_SD_AAC_MULT5 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_SD_AAC_MULT5_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_SD_AAC_MULT5_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_SD_MPEG1_L3 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_SD_MPEG1_L3_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_SD_MPEG1_L3_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_HP_SD_MPEG1_L2_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_HP_SD_MPEG1_L2_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_SD_AC3 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_SD_AC3_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_MP_SD_AC3_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_HD_DTS_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_HD_DTS_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  WMVMED_BASE {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  WMVMED_FULL {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  WMVMED_PRO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  WMVHIGH_FULL {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  WMVHIGH_PRO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  VC1_ASF_AP_L1_WMA {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  VC1_ASF_AP_L2_WMA {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  VC1_ASF_AP_L3_WMA {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  VC1_TS_AP_L1_AC3_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  VC1_TS_AP_L2_AC3_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  VC1_TS_HD_DTS_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  VC1_TS_HD_DTS_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_MP4_ASP_AAC {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_MP4_SP_L6_AAC {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_MP4_NDSD {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_TS_ASP_AAC {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_TS_ASP_AAC_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_TS_ASP_AAC_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_TS_ASP_MPEG1_L3 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_TS_ASP_MPEG1_L3_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_TS_ASP_MPEG1_L3_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_TS_ASP_MPEG2_L2 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_TS_ASP_MPEG2_L2_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_TS_ASP_MPEG2_L2_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_TS_ASP_AC3 {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_TS_ASP_AC3_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_TS_ASP_AC3_ISO {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_TS_HD_50_LPCM_T {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_MP4_LPCM {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_3GPP_SP_L0B_AAC {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_P2_3GPP_SP_L0B_AMR {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  AVC_3GPP_BL_QCIF15_AAC {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_H263_3GPP_P0_L10_AMR {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
}, 

  MPEG4_H263_MP4_P0_L10_AAC {
	override
	public MediaFileType getFileType()
	{
		// TODO Auto-generated method stub
		return MediaFileType.VIDEO;
	}
};

  public abstract MediaFileType getFileType();

  public static List<MediaFormatProfile> getSupportedMediaFormatProfiles()
  {
    return Arrays.asList(values());
  }
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.dlna.MediaFormatProfile
 * JD-Core Version:    0.6.2
 */