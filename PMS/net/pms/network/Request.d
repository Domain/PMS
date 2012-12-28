/*
 * PS3 Media Server, for streaming any medias to your PS3.
 * Copyright (C) 2008  A.Brochard
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; version 2
 * of the License only.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
module net.pms.network.Request;

import net.pms.PMS;
import net.pms.configuration.RendererConfiguration;
import net.pms.dlna.DLNAMediaInfo;
import net.pms.dlna.DLNAMediaSubtitle;
import net.pms.dlna.DLNAResource;
import net.pms.dlna.Range;
import net.pms.external.StartStopListenerDelegate;
import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.MalformedURLException;
import java.net.Socket;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.all;

import org.apache.commons.lang.StringUtils : isNotBlank;

public class Request : HTTPResource {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!Request();

	private const static String CRLF = "\r\n";
	private const static String HTTP_200_OK = "HTTP/1.1 200 OK";
	private const static String HTTP_500 = "HTTP/1.1 500 Internal Server Error";
	private const static String HTTP_206_OK = "HTTP/1.1 206 Partial Content";
	private const static String HTTP_200_OK_10 = "HTTP/1.0 200 OK";
	private const static String HTTP_206_OK_10 = "HTTP/1.0 206 Partial Content";
	private const static String CONTENT_TYPE_UTF8 = "CONTENT-TYPE: text/xml; charset=\"utf-8\"";
	private const static String CONTENT_TYPE = "Content-Type: text/xml; charset=\"utf-8\"";
	private static SimpleDateFormat sdf = new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss", Locale.US);
	private String method;
	private String argument;
	private String soapaction;
	private String content;
	private OutputStream output;
	private String objectID;
	private int startingIndex;
	private int requestCount;
	private String browseFlag;
	private long lowRange;
	private InputStream inputStream;
	private RendererConfiguration mediaRenderer;
	private String transferMode;
	private String contentFeatures;
	private double timeseek;
	private double timeRangeEnd;
	private long highRange;
	private bool http10;

	public RendererConfiguration getMediaRenderer() {
		return mediaRenderer;
	}

	public void setMediaRenderer(RendererConfiguration mediaRenderer) {
		this.mediaRenderer = mediaRenderer;
	}

	public InputStream getInputStream() {
		return inputStream;
	}

	public long getLowRange() {
		return lowRange;
	}

	public void setLowRange(long lowRange) {
		this.lowRange = lowRange;
	}

	public String getTransferMode() {
		return transferMode;
	}

	public void setTransferMode(String transferMode) {
		this.transferMode = transferMode;
	}

	public String getContentFeatures() {
		return contentFeatures;
	}

	public void setContentFeatures(String contentFeatures) {
		this.contentFeatures = contentFeatures;
	}

	public double getTimeseek() {
		return timeseek;
	}

	public void setTimeseek(double timeseek) {
		this.timeseek = timeseek;
	}

	public void setTimeRangeEnd(double timeRangeEnd) {
		this.timeRangeEnd = timeRangeEnd;
	}

	public long getHighRange() {
		return highRange;
	}

	public void setHighRange(long highRange) {
		this.highRange = highRange;
	}

	public bool isHttp10() {
		return http10;
	}

	public void setHttp10(bool http10) {
		this.http10 = http10;
	}

	public this(String method, String argument) {
		this.method = method;
		this.argument = argument;
	}

	public String getSoapaction() {
		return soapaction;
	}

	public void setSoapaction(String soapaction) {
		this.soapaction = soapaction;
	}

	public String getTextContent() {
		return content;
	}

	public void setTextContent(String content) {
		this.content = content;
	}

	public String getMethod() {
		return method;
	}

	public String getArgument() {
		return argument;
	}

	public void answer(OutputStream output, StartStopListenerDelegate startStopListenerDelegate) {
		this.output = output;

		long CLoverride = -2; // 0 and above are valid Content-Length values, -1 means omit
		if (lowRange != 0 || highRange != 0) {
			output(output, http10 ? HTTP_206_OK_10 : HTTP_206_OK);
		} else {
			if (soapaction !is null && soapaction.indexOf("ContentDirectory:1#X_GetFeatureList") > -1) {
				//  If we don't return a 500 error, Samsung 2012 TVs time out.
				output(output, HTTP_500);
			} else {
				output(output, http10 ? HTTP_200_OK_10 : HTTP_200_OK);
			}
		}

		StringBuilder response = new StringBuilder();
		DLNAResource dlna = null;
		bool xbox = mediaRenderer.isXBOX();

		// Samsung 2012 TVs have a problematic preceding slash that needs to be removed.
		if (argument.startsWith("/")) {
			LOGGER.trace("Stripping preceding slash from: " ~ argument);
			argument = argument.substring(1);
		}

		if ((method.opEquals("GET") || method.opEquals("HEAD")) && argument.startsWith("console/")) {
			output(output, "Content-Type: text/html");
			response.append(HTMLConsole.servePage(argument.substring(8)));
		} else if ((method.opEquals("GET") || method.opEquals("HEAD")) && argument.startsWith("get/")) {
			String id = argument.substring(argument.indexOf("get/") + 4, argument.lastIndexOf("/"));
			id = id.replace("%24", "$"); // popcorn hour ?
			List/*<DLNAResource>*/ files = PMS.get().getRootFolder(mediaRenderer).getDLNAResources(id, false, 0, 0, mediaRenderer);

			if (transferMode !is null) {
				output(output, "TransferMode.DLNA.ORG: " ~ transferMode);
			}

			if (files.size() == 1) {
				// DNLAresource was found.
				dlna = files.get(0);
				String fileName = argument.substring(argument.lastIndexOf("/") + 1);

				if (fileName.startsWith("thumbnail0000")) {
					// This is a request for a thumbnail file.
					output(output, "Content-Type: " ~ dlna.getThumbnailContentType());
					output(output, "Accept-Ranges: bytes");
					output(output, "Expires: " ~ getFUTUREDATE() ~ " GMT");
					output(output, "Connection: keep-alive");

					if (mediaRenderer.isMediaParserV2()) {
						dlna.checkThumbnail();
					}

					inputStream = dlna.getThumbnailInputStream();
				} else if (fileName.indexOf("subtitle0000") > -1) {
					// This is a request for a subtitle file
					output(output, "Content-Type: text/plain");
					output(output, "Expires: " ~ getFUTUREDATE() ~ " GMT");
					List/*<DLNAMediaSubtitle>*/ subs = dlna.getMedia().getSubtitleTracksList();

					if (subs !is null && !subs.isEmpty()) {
						// TODO: maybe loop subs to get the requested subtitle type instead of using the first one
						DLNAMediaSubtitle sub = subs.get(0);
						// XXX external file is null if the first subtitle track is embedded:
						// http://www.ps3mediaserver.org/forum/viewtopic.php?f=3&t=15805&p=75534#p75534
						if (sub.isExternal()) {
							inputStream = new java.io.FileInputStream(sub.getExternalFile());
						}
					}
				} else {
					// This is a request for a regular file.
					String name = dlna.getDisplayName(mediaRenderer);
					inputStream = dlna.getInputStream(Range.create(lowRange, highRange, timeseek, timeRangeEnd), mediaRenderer);
					if (inputStream is null) {
						// No inputStream indicates that transcoding / remuxing probably crashed.
						LOGGER.error("There is no inputstream to return for " ~ name);
					} else {
						startStopListenerDelegate.start(dlna);
						output(output, "Content-Type: " ~ getRendererMimeType(dlna.mimeType(), mediaRenderer));

						// Some renderers (like Samsung devices) allow a custom header for a subtitle URL
						String subtitleHttpHeader = mediaRenderer.getSubtitleHttpHeader();

						if (subtitleHttpHeader !is null && !"".opEquals(subtitleHttpHeader)) {
							// Device allows a custom subtitle HTTP header; construct it
							List/*<DLNAMediaSubtitle>*/ subs = dlna.getMedia().getSubtitleTracksList();

							if (subs !is null && !subs.isEmpty()) {
								DLNAMediaSubtitle sub = subs.get(0);
								String subtitleUrl;
								String subExtension = sub.getType().getExtension();
								if (isNotBlank(subExtension)) {
									subtitleUrl = "http://" ~ PMS.get().getServer().getHost()
											~ ':' ~ PMS.get().getServer().getPort() ~ "/get/"
											~ id ~ "/subtitle0000." ~ subExtension;
								} else {
									subtitleUrl = "http://" ~ PMS.get().getServer().getHost()
											~ ':' ~ PMS.get().getServer().getPort() ~ "/get/"
											~ id ~ "/subtitle0000";
								}
								output(output, subtitleHttpHeader ~ ": " ~ subtitleUrl);
							}
						}

						DLNAMediaInfo media = dlna.getMedia();

						if (media !is null) {
							if (StringUtils.isNotBlank(media.getContainer())) {
								name ~= " [container: " ~ media.getContainer() ~ "]";
							}

							if (StringUtils.isNotBlank(media.getCodecV())) {
								name ~= " [video: " ~ media.getCodecV() ~ "]";
							}
						}

						PMS.get().getFrame().setStatusLine("Serving " ~ name);

						// Response generation:
						// We use -1 for arithmetic convenience but don't send it as a value.
						// If Content-Length < 0 we omit it, for Content-Range we use '*' to signify unspecified.

						bool chunked = mediaRenderer.isChunkedTransfer();

						// Determine the total size. Note: when transcoding the length is
						// not known in advance, so DLNAMediaInfo.TRANS_SIZE will be returned instead.

						long totalsize = dlna.length(mediaRenderer);

						if (chunked && totalsize == DLNAMediaInfo.TRANS_SIZE) {
							// In chunked mode we try to avoid arbitrary values.
							totalsize = -1;
						}

						long remaining = totalsize - lowRange;
						long requested = highRange - lowRange;

						if (requested != 0) {
							// Determine the range (i.e. smaller of known or requested bytes)
							long bytes = remaining > -1 ? remaining : inputStream.available();

							if (requested > 0 && bytes > requested) {
								bytes = requested + 1;
							}

							// Calculate the corresponding highRange (this is usually redundant).
							highRange = lowRange + bytes - (bytes > 0 ? 1 : 0);

							LOGGER.trace((chunked ? "Using chunked response. " : "") ~ "Sending " ~ bytes ~ " bytes.");

							output(output, "Content-Range: bytes " ~ lowRange.toString()
									~ "-" ~ (highRange > -1 ? highRange.toString() : "*")
									~ "/" ~ (totalsize > -1 ? totalsize.toString() : "*"));

							// Content-Length refers to the current chunk size here, though in chunked
							// mode if the request is open-ended and totalsize is unknown we omit it.
							if (chunked && requested < 0 && totalsize < 0) {
								CLoverride = -1;
							} else {
								CLoverride = bytes;
							}
						} else {
							// Content-Length refers to the total remaining size of the stream here.
							CLoverride = remaining;
						}

						if (contentFeatures !is null) {
							output(output, "ContentFeatures.DLNA.ORG: " ~ dlna.getDlnaContentFeatures());
						}

						if (dlna.getPlayer() is null || xbox) {
							output(output, "Accept-Ranges: bytes");
						}

						output(output, "Connection: keep-alive");
					}
				}
			}
		} else if ((method.opEquals("GET") || method.opEquals("HEAD")) && (argument.toLowerCase().endsWith(".png") || argument.toLowerCase().endsWith(".jpg") || argument.toLowerCase().endsWith(".jpeg"))) {
			if (argument.toLowerCase().endsWith(".png")) {
				output(output, "Content-Type: image/png");
			} else {
				output(output, "Content-Type: image/jpeg");
			}

			output(output, "Accept-Ranges: bytes");
			output(output, "Connection: keep-alive");
			output(output, "Expires: " ~ getFUTUREDATE() ~ " GMT");
			inputStream = getResourceInputStream(argument);
		} else if ((method.opEquals("GET") || method.opEquals("HEAD")) && (argument.opEquals("description/fetch") || argument.endsWith("1.0.xml"))) {
			String profileName = PMS.getConfiguration().getProfileName();
			output(output, CONTENT_TYPE);
			output(output, "Cache-Control: no-cache");
			output(output, "Expires: 0");
			output(output, "Accept-Ranges: bytes");
			output(output, "Connection: keep-alive");
			inputStream = getResourceInputStream((argument.opEquals("description/fetch") ? "PMS.xml" : argument));

			if (argument.opEquals("description/fetch")) {
				byte[] b = new byte[inputStream.available()];
				inputStream.read(b);
				String s = new String(b);
				s = s.replace("[uuid]", PMS.get().usn());//.substring(0, PMS.get().usn().length()-2));
				s = s.replace("[host]", PMS.get().getServer().getHost());
				s = s.replace("[port]", "" ~ PMS.get().getServer().getPort());

				if (xbox) {
					LOGGER._debug("DLNA changes for Xbox 360");
					s = s.replace("PS3 Media Server", "PS3 Media Server [" ~ profileName ~ "] : Windows Media Connect");
					s = s.replace("<modelName>PMS</modelName>", "<modelName>Windows Media Connect</modelName>");
					s = s.replace("<serviceList>", "<serviceList>" ~ CRLF ~ "<service>" ~ CRLF
							~ "<serviceType>urn:microsoft.com:service:X_MS_MediaReceiverRegistrar:1</serviceType>" ~ CRLF
							~ "<serviceId>urn:microsoft.com:serviceId:X_MS_MediaReceiverRegistrar</serviceId>" ~ CRLF
							~ "<SCPDURL>/upnp/mrr/scpd</SCPDURL>" ~ CRLF
							~ "<controlURL>/upnp/mrr/control</controlURL>" ~ CRLF
							~ "</service>" ~ CRLF);


				} else {
					s = s.replace("PS3 Media Server", "PS3 Media Server [" ~ profileName ~ "]");
				}

				inputStream = new ByteArrayInputStream(s.getBytes());
			}
		} else if (method.opEquals("POST") && (argument.contains("MS_MediaReceiverRegistrar_control") || argument.contains("mrr/control"))) {
			output(output, CONTENT_TYPE_UTF8);
			response.append(HTTPXMLHelper.XML_HEADER);
			response.append(CRLF);
			response.append(HTTPXMLHelper.SOAP_ENCODING_HEADER);
			response.append(CRLF);

			if (soapaction !is null && soapaction.contains("IsAuthorized")) {
				response.append(HTTPXMLHelper.XBOX_2);
				response.append(CRLF);
			} else if (soapaction !is null && soapaction.contains("IsValidated")) {
				response.append(HTTPXMLHelper.XBOX_1);
				response.append(CRLF);
			}

			response.append(HTTPXMLHelper.SOAP_ENCODING_FOOTER);
			response.append(CRLF);
		} else if (method.opEquals("POST") && argument.endsWith("upnp/control/connection_manager")) {
			output(output, CONTENT_TYPE_UTF8);

			if (soapaction !is null && soapaction.indexOf("ConnectionManager:1#GetProtocolInfo") > -1) {
				response.append(HTTPXMLHelper.XML_HEADER);
				response.append(CRLF);
				response.append(HTTPXMLHelper.SOAP_ENCODING_HEADER);
				response.append(CRLF);
				response.append(HTTPXMLHelper.PROTOCOLINFO_RESPONSE);
				response.append(CRLF);
				response.append(HTTPXMLHelper.SOAP_ENCODING_FOOTER);
				response.append(CRLF);
			}
		} else if (method.opEquals("SUBSCRIBE")) {
			if (soapaction is null) {
				// ignore this
				return;
			}

			output(output, CONTENT_TYPE_UTF8);
			output(output,"Content-Length: 0");
			output(output,"Connection: close");
			output(output,"SID: "~PMS.get().usn());
			output(output,"Server: "~PMS.get().getServerName());
			output(output,"Timeout: Second-1800");
			output(output,"");
			output.flush();
			// output.close();

			String cb = soapaction.replace("<", "").replace(">", "");

			try {
				URL soapActionUrl = new URL(cb);
				String addr = soapActionUrl.getHost();
				int port = soapActionUrl.getPort();
				Socket sock = new Socket(addr,port);
				OutputStream _out = sock.getOutputStream();

				output(_out,"NOTIFY /"~argument~" HTTP/1.1");
				output(_out,"SID: "~PMS.get().usn());
				output(_out,"SEQ: "~0);
				output(_out,"NT: upnp:event");
				output(_out,"NTS: upnp:propchange");
				output(_out,"HOST: " ~ addr ~ ":" ~ port.toString());
				output(_out, CONTENT_TYPE_UTF8);
			} catch (MalformedURLException ex) {
				LOGGER._debug("Cannot parse address and port from soap action \"" ~ soapaction ~ "\"", ex);
			}
			
			if (argument.contains("connection_manager")) {
				response.append(HTTPXMLHelper.eventHeader("urn:schemas-upnp-org:service:ConnectionManager:1"));
				response.append(HTTPXMLHelper.eventProp("SinkProtocolInfo"));
				response.append(HTTPXMLHelper.eventProp("SourceProtocolInfo"));
				response.append(HTTPXMLHelper.eventProp("CurrentConnectionIDs"));
				response.append(HTTPXMLHelper.EVENT_FOOTER);
			} else if (argument.contains("content_directory")) {
				response.append(HTTPXMLHelper.eventHeader("urn:schemas-upnp-org:service:ContentDirectory:1"));
				response.append(HTTPXMLHelper.eventProp("TransferIDs"));
				response.append(HTTPXMLHelper.eventProp("ContainerUpdateIDs"));
				response.append(HTTPXMLHelper.eventProp("SystemUpdateID",DLNAResource.getSystemUpdateId().toString()));
				response.append(HTTPXMLHelper.EVENT_FOOTER);
			}
		} else if (method.opEquals("POST") && argument.endsWith("upnp/control/content_directory")) {
			output(output, CONTENT_TYPE_UTF8);

			if (soapaction !is null && soapaction.indexOf("ContentDirectory:1#GetSystemUpdateID") > -1) {
				response.append(HTTPXMLHelper.XML_HEADER);
				response.append(CRLF);
				response.append(HTTPXMLHelper.SOAP_ENCODING_HEADER);
				response.append(CRLF);
				response.append(HTTPXMLHelper.GETSYSTEMUPDATEID_HEADER);
				response.append(CRLF);
				response.append("<Id>").append(DLNAResource.getSystemUpdateId()).append("</Id>");
				response.append(CRLF);
				response.append(HTTPXMLHelper.GETSYSTEMUPDATEID_FOOTER);
				response.append(CRLF);
				response.append(HTTPXMLHelper.SOAP_ENCODING_FOOTER);
				response.append(CRLF);
			} else if (soapaction !is null && soapaction.indexOf("ContentDirectory:1#GetSortCapabilities") > -1) {
				response.append(HTTPXMLHelper.XML_HEADER);
				response.append(CRLF);
				response.append(HTTPXMLHelper.SOAP_ENCODING_HEADER);
				response.append(CRLF);
				response.append(HTTPXMLHelper.SORTCAPS_RESPONSE);
				response.append(CRLF);
				response.append(HTTPXMLHelper.SOAP_ENCODING_FOOTER);
				response.append(CRLF);
			} else if (soapaction !is null && soapaction.indexOf("ContentDirectory:1#X_GetFeatureList") > -1) { // Added for Samsung 2012 TVs
				response.append(HTTPXMLHelper.XML_HEADER);
				response.append(CRLF);
				response.append(HTTPXMLHelper.SOAP_ENCODING_HEADER);
				response.append(CRLF);
				response.append(HTTPXMLHelper.UPNP_INVALID_ACTION);
				response.append(CRLF);
				response.append(HTTPXMLHelper.SOAP_ENCODING_FOOTER);
				response.append(CRLF);
			} else if (soapaction !is null && soapaction.indexOf("ContentDirectory:1#GetSearchCapabilities") > -1) {
				response.append(HTTPXMLHelper.XML_HEADER);
				response.append(CRLF);
				response.append(HTTPXMLHelper.SOAP_ENCODING_HEADER);
				response.append(CRLF);
				response.append(HTTPXMLHelper.SEARCHCAPS_RESPONSE);
				response.append(CRLF);
				response.append(HTTPXMLHelper.SOAP_ENCODING_FOOTER);
				response.append(CRLF);
			} else if (soapaction !is null && (soapaction.contains("ContentDirectory:1#Browse")
					|| soapaction.contains("ContentDirectory:1#Search"))) {
				objectID = getEnclosingValue(content, "<ObjectID>", "</ObjectID>");
				String containerID = null;

				if ((objectID is null || objectID.length() == 0) && xbox) {
					containerID = getEnclosingValue(content, "<ContainerID>", "</ContainerID>");
					if (!containerID.contains("$")) {
						objectID = "0";
					} else {
						objectID = containerID;
						containerID = null;
					}
				}

				Object sI = getEnclosingValue(content, "<StartingIndex>", "</StartingIndex>");
				Object rC = getEnclosingValue(content, "<RequestedCount>", "</RequestedCount>");
				browseFlag = getEnclosingValue(content, "<BrowseFlag>", "</BrowseFlag>");

				if (sI !is null) {
					startingIndex = Integer.parseInt(sI.toString());
				}

				if (rC !is null) {
					requestCount = Integer.parseInt(rC.toString());
				}

				response.append(HTTPXMLHelper.XML_HEADER);
				response.append(CRLF);
				response.append(HTTPXMLHelper.SOAP_ENCODING_HEADER);
				response.append(CRLF);

				if (soapaction !is null && soapaction.contains("ContentDirectory:1#Search")) {
					response.append(HTTPXMLHelper.SEARCHRESPONSE_HEADER);
				} else {
					response.append(HTTPXMLHelper.BROWSERESPONSE_HEADER);
				}

				response.append(CRLF);
				response.append(HTTPXMLHelper.RESULT_HEADER);

				response.append(HTTPXMLHelper.DIDL_HEADER);

				if (soapaction !is null && soapaction.contains("ContentDirectory:1#Search")) {
					browseFlag = "BrowseDirectChildren";
				}

				// XBOX virtual containers ... doh
				String searchCriteria = null;
				if (xbox && PMS.getConfiguration().getUseCache() && PMS.get().getLibrary() !is null && containerID !is null) {
					if (containerID.opEquals("7") && PMS.get().getLibrary().getAlbumFolder() !is null) {
						objectID = PMS.get().getLibrary().getAlbumFolder().getResourceId();
					} else if (containerID.opEquals("6") && PMS.get().getLibrary().getArtistFolder() !is null) {
						objectID = PMS.get().getLibrary().getArtistFolder().getResourceId();
					} else if (containerID.opEquals("5") && PMS.get().getLibrary().getGenreFolder() !is null) {
						objectID = PMS.get().getLibrary().getGenreFolder().getResourceId();
					} else if (containerID.opEquals("F") && PMS.get().getLibrary().getPlaylistFolder() !is null) {
						objectID = PMS.get().getLibrary().getPlaylistFolder().getResourceId();
					} else if (containerID.opEquals("4") && PMS.get().getLibrary().getAllFolder() !is null) {
						objectID = PMS.get().getLibrary().getAllFolder().getResourceId();
					} else if (containerID.opEquals("1")) {
						String artist = getEnclosingValue(content, "upnp:artist = &quot;", "&quot;)");
						if (artist !is null) {
							objectID = PMS.get().getLibrary().getArtistFolder().getResourceId();
							searchCriteria = artist;
						}
					}
				}

				List/*<DLNAResource>*/ files = PMS.get().getRootFolder(mediaRenderer).getDLNAResources(
					objectID,
					browseFlag !is null && browseFlag.opEquals("BrowseDirectChildren"),
					startingIndex,
					requestCount,
					mediaRenderer
				);

				if (searchCriteria !is null && files !is null) {
					for (int i = files.size() - 1; i >= 0; i--) {
						if (!files.get(i).getName().opEquals(searchCriteria)) {
							files.remove(i);
						}
					}

					if (files.size() > 0) {
						files = files.get(0).getChildren();
					}
				}

				int minus = 0;
				if (files !is null) {
					foreach (DLNAResource uf ; files) {
						if (xbox && containerID !is null) {
							uf.setFakeParentId(containerID);
						}

						if (uf.isCompatible(mediaRenderer) && (uf.getPlayer() is null || uf.getPlayer().isPlayerCompatible(mediaRenderer))) {
							response.append(uf.toString(mediaRenderer));
						} else {
							minus++;
						}
					}
				}

				response.append(HTTPXMLHelper.DIDL_FOOTER);

				response.append(HTTPXMLHelper.RESULT_FOOTER);
				response.append(CRLF);
				int filessize = 0;

				if (files !is null) {
					filessize = files.size();
				}

				response.append("<NumberReturned>").append(filessize - minus).append("</NumberReturned>");
				response.append(CRLF);
				DLNAResource parentFolder = null;

				if (files !is null && filessize > 0) {
					parentFolder = files.get(0).getParent();
				}

				if (browseFlag !is null && browseFlag.opEquals("BrowseDirectChildren") && mediaRenderer.isMediaParserV2() && mediaRenderer.isDLNATreeHack()) {
					// with the new parser, files are parsed and analyzed *before*
					// creating the DLNA tree, every 10 items (the ps3 asks 10 by 10),
					// so we do not know exactly the total number of items in the DLNA folder to send
					// (regular files, plus the #transcode folder, maybe the #imdb one, also files can be
					// invalidated and hidden if format is broken or encrypted, etc.).
					// let's send a fake total size to force the renderer to ask following items
					int totalCount = startingIndex + requestCount + 1; // returns 11 when 10 asked
					if (filessize - minus <= 0) { // if no more elements, send startingIndex
						totalCount = startingIndex;
					}

					response.append("<TotalMatches>").append(totalCount).append("</TotalMatches>");
				} else if (browseFlag!=null && browseFlag.opEquals("BrowseDirectChildren")) {
					response.append("<TotalMatches>").append(((parentFolder !is null) ? parentFolder.childrenNumber() : filessize) - minus).append("</TotalMatches>");
				} else {
					// from upnp spec: If BrowseMetadata is specified in the BrowseFlags then TotalMatches = 1
					response.append("<TotalMatches>1</TotalMatches>");
				}

				response.append(CRLF);
				response.append("<UpdateID>");

				if (parentFolder !is null) {
					response.append(parentFolder.getUpdateId());
				} else {
					response.append("1");
				}

				response.append("</UpdateID>");
				response.append(CRLF);

				if (soapaction !is null && soapaction.contains("ContentDirectory:1#Search")) {
					response.append(HTTPXMLHelper.SEARCHRESPONSE_FOOTER);
				} else {
					response.append(HTTPXMLHelper.BROWSERESPONSE_FOOTER);
				}

				response.append(CRLF);
				response.append(HTTPXMLHelper.SOAP_ENCODING_FOOTER);
				response.append(CRLF);
				// LOGGER.trace(response.toString());
			}
		}

		output(output, "Server: " ~ PMS.get().getServerName());

		if (response.length() > 0) {
			byte responseData[] = response.toString().getBytes("UTF-8");
			output(output, "Content-Length: " ~ responseData.length);
			output(output, "");
			if (!method.opEquals("HEAD")) {
				output.write(responseData);
				//LOGGER.trace(response.toString());
			}
		} else if (inputStream !is null) {
			if (CLoverride > -2) {
				// Content-Length override has been set, send or omit as appropriate
				if (CLoverride > -1 && CLoverride != DLNAMediaInfo.TRANS_SIZE) {
					// Since PS3 firmware 2.50, it is wiser not to send an arbitrary Content-Length,
					// as the PS3 will display a network error and request the last seconds of the
					// transcoded video. Better to send no Content-Length at all.
					output(output, "Content-Length: " ~ CLoverride);
				}
			} else {
				int cl = inputStream.available();
				LOGGER.trace("Available Content-Length: " ~ cl);
				output(output, "Content-Length: " ~ cl);
			}

			if (timeseek > 0 && dlna !is null) {
				String timeseekValue = DLNAMediaInfo.getDurationString(timeseek);
				String timetotalValue = dlna.getMedia().getDurationString();
				output(output, "TimeSeekRange.dlna.org: npt=" ~ timeseekValue ~ "-" ~ timetotalValue ~ "/" ~ timetotalValue);
				output(output, "X-Seek-Range: npt=" ~ timeseekValue ~ "-" ~ timetotalValue ~ "/" ~ timetotalValue);
			}

			output(output, "");
			int sendB = 0;

			if (lowRange != DLNAMediaInfo.ENDFILE_POS && !method.opEquals("HEAD")) {
				sendB = sendBytes(inputStream); //, ((lowRange > 0 && highRange > 0)?(highRange-lowRange):-1)
			}

			LOGGER.trace("Sending stream: " ~ sendB.toString() ~ " bytes of " ~ argument);
			PMS.get().getFrame().setStatusLine(null);
		} else { // inputStream is null
			if (lowRange > 0 && highRange > 0) {
				output(output, "Content-Length: " ~ (highRange - lowRange + 1).toString());
			} else {
				output(output, "Content-Length: 0");
			}

			output(output, "");
		}
	}

	private void output(OutputStream output, String line) {
		output.write((line + CRLF).getBytes("UTF-8"));
		LOGGER.trace("Wrote on socket: " ~ line);
	}

	private String getFUTUREDATE() {
		sdf.setTimeZone(TimeZone.getTimeZone("GMT"));
		return sdf.format(new Date(10000000000L + System.currentTimeMillis()));
	}

	// VISTA tip ?: netsh interface tcp set global autotuninglevel=disabled
	private int sendBytes(InputStream fis) {
		byte[] buffer = new byte[32 * 1024];
		int bytes = 0;
		int sendBytes = 0;

		try {
			while ((bytes = fis.read(buffer)) != -1) {
				output.write(buffer, 0, bytes);
				sendBytes += bytes;
			}
		} catch (IOException e) {
			LOGGER.trace("Sending stream with premature end: " ~ sendBytes.toString() ~ " bytes of " ~ argument ~ ". Reason: " ~ e.getMessage());
		} finally {
			fis.close();
		}

		return sendBytes;
	}

	private String getEnclosingValue(String content, String leftTag, String rightTag) {
		String result = null;
		int leftTagPos = content.indexOf(leftTag);
		int rightTagPos = content.indexOf(rightTag, leftTagPos + 1);

		if (leftTagPos > -1 && rightTagPos > leftTagPos) {
			result = content.substring(leftTagPos + leftTag.length(), rightTagPos);
		}

		return result;
	}
}
