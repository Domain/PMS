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
module net.pms.network.RequestHandlerV2;

import net.pms.PMS;
import net.pms.configuration.RendererConfiguration;
import net.pms.external.StartStopListenerDelegate;
import org.jboss.netty.buffer.ChannelBuffer;
import org.jboss.netty.buffer.ChannelBuffers;
//import org.jboss.netty.channel.*;
import org.jboss.netty.channel.group.ChannelGroup;
import org.jboss.netty.handler.codec.frame.TooLongFrameException;
//import org.jboss.netty.handler.codec.http.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.exceptions;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.nio.channels.ClosedChannelException;
import java.nio.charset.Charset;
import java.util.StringTokenizer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class RequestHandlerV2 : SimpleChannelUpstreamHandler {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!RequestHandlerV2();
	private static immutable Pattern TIMERANGE_PATTERN = Pattern.compile(
		"timeseekrange\\.dlna\\.org\\W*npt\\W*=\\W*([\\d\\.:]+)?\\-?([\\d\\.:]+)?",
		Pattern.CASE_INSENSITIVE
	);
	private HttpRequest nettyRequest;
	private ChannelGroup group;

	// Used to filter out known headers when the renderer is not recognized
	private const static String[] KNOWN_HEADERS = [
		"Accept",
		"Accept-Language",
		"Accept-Encoding",
		"Callback",
		"Connection",
		"Content-Length",
		"Content-Type",
		"Date",
		"Host",
		"Nt",
		"Sid",
		"Timeout",
		"User-Agent"
	];
	
	public this(ChannelGroup group) {
		this.group = group;
	}

	override
	public void messageReceived(ChannelHandlerContext ctx, MessageEvent e)
		{
		RequestV2 request = null;
		RendererConfiguration renderer = null;
		String userAgentString = null;
		StringBuilder unknownHeaders = new StringBuilder();
		String separator = "";
		
		HttpRequest nettyRequest = this.nettyRequest = cast(HttpRequest) e.getMessage();

		InetSocketAddress remoteAddress = cast(InetSocketAddress) e.getChannel().getRemoteAddress();
		InetAddress ia = remoteAddress.getAddress();

		// Apply the IP filter
		if (filterIp(ia)) {
			e.getChannel().close();
			LOGGER.trace("Access denied for address " ~ ia ~ " based on IP filter");
			return;
		}

		LOGGER.trace("Opened request handler on socket " ~ remoteAddress);
		PMS.get().getRegistry().disableGoToSleep();

		if (HttpMethod.GET.opEquals(nettyRequest.getMethod())) {
			request = new RequestV2("GET", nettyRequest.getUri().substring(1));
		} else if (HttpMethod.POST.opEquals(nettyRequest.getMethod())) {
			request = new RequestV2("POST", nettyRequest.getUri().substring(1));
		} else if (HttpMethod.HEAD.opEquals(nettyRequest.getMethod())) {
			request = new RequestV2("HEAD", nettyRequest.getUri().substring(1));
		} else {
			request = new RequestV2(nettyRequest.getMethod().getName(), nettyRequest.getUri().substring(1));
		}

		LOGGER.trace("Request: " ~ nettyRequest.getProtocolVersion().getText() ~ " : " ~ request.getMethod() ~ " : " ~ request.getArgument());

		if (nettyRequest.getProtocolVersion().getMinorVersion() == 0) {
			request.setHttp10(true);
		}

		// The handler makes a couple of attempts to recognize a renderer from its requests.
		// IP address matches from previous requests are preferred, when that fails request
		// header matches are attempted and if those fail as well we're stuck with the
		// default renderer.

		// Attempt 1: try to recognize the renderer by its socket address from previous requests
		renderer = RendererConfiguration.getRendererConfigurationBySocketAddress(ia);

		if (renderer !is null) {
			PMS.get().setRendererfound(renderer);
			request.setMediaRenderer(renderer);
			LOGGER.trace("Matched media renderer \"" ~ renderer.getRendererName() ~ "\" based on address " ~ ia);
		}
		
		foreach (String name ; nettyRequest.getHeaderNames()) {
			String headerLine = name ~ ": " ~ nettyRequest.getHeader(name);
			LOGGER.trace("Received on socket: " ~ headerLine);

			if (renderer is null && headerLine !is null
					&& headerLine.toUpperCase().startsWith("USER-AGENT")
					&& request !is null) {
				userAgentString = headerLine.substring(headerLine.indexOf(":") + 1).trim();

				// Attempt 2: try to recognize the renderer by matching the "User-Agent" header
				renderer = RendererConfiguration.getRendererConfigurationByUA(userAgentString);

				if (renderer !is null) {
					request.setMediaRenderer(renderer);
					renderer.associateIP(ia);	// Associate IP address for later requests
					PMS.get().setRendererfound(renderer);
					LOGGER.trace("Matched media renderer \"" ~ renderer.getRendererName() ~ "\" based on header \"" ~ headerLine ~ "\"");
				}
			}

			if (renderer is null && headerLine !is null && request !is null) {
				// Attempt 3: try to recognize the renderer by matching an additional header
				renderer = RendererConfiguration.getRendererConfigurationByUAAHH(headerLine);

				if (renderer !is null) {
					request.setMediaRenderer(renderer);
					renderer.associateIP(ia);	// Associate IP address for later requests
					PMS.get().setRendererfound(renderer);
					LOGGER.trace("Matched media renderer \"" ~ renderer.getRendererName() ~ "\" based on header \"" ~ headerLine ~ "\"");
				}
			}

			try {
				StringTokenizer s = new StringTokenizer(headerLine);
				String temp = s.nextToken();
				if (request !is null && temp.toUpperCase().opEquals("SOAPACTION:")) {
					request.setSoapaction(s.nextToken());
				} else if (request !is null && temp.toUpperCase().opEquals("CALLBACK:")) {
					request.setSoapaction(s.nextToken());
				} else if (headerLine.toUpperCase().indexOf("RANGE: BYTES=") > -1) {
					String nums = headerLine.substring(
						headerLine.toUpperCase().indexOf(
						"RANGE: BYTES=") + 13).trim();
					StringTokenizer st = new StringTokenizer(nums, "-");
					if (!nums.startsWith("-")) {
						request.setLowRange(Long.parseLong(st.nextToken()));
					}
					if (!nums.startsWith("-") && !nums.endsWith("-")) {
						request.setHighRange(Long.parseLong(st.nextToken()));
					} else {
						request.setHighRange(-1);
					}
				} else if (headerLine.toLowerCase().indexOf("transfermode.dlna.org:") > -1) {
					request.setTransferMode(headerLine.substring(headerLine.toLowerCase().indexOf("transfermode.dlna.org:") + 22).trim());
				} else if (headerLine.toLowerCase().indexOf("getcontentfeatures.dlna.org:") > -1) {
					request.setContentFeatures(headerLine.substring(headerLine.toLowerCase().indexOf("getcontentfeatures.dlna.org:") + 28).trim());
				} else {
					Matcher matcher = TIMERANGE_PATTERN.matcher(headerLine);
					if (matcher.find()) {
						String first = matcher.group(1);
						if (first !is null) {
							request.setTimeRangeStartString(first);
						}
						String end = matcher.group(2);
						if (end !is null) {
							request.setTimeRangeEndString(end);
						}
					}  else {
						 // If we made it to here, none of the previous header checks matched.
						 // Unknown headers make interesting logging info when we cannot recognize
						 // the media renderer, so keep track of the truly unknown ones.
						bool isKnown = false;

						// Try to match possible known headers.
						foreach (String knownHeaderString ; KNOWN_HEADERS) {
							if (headerLine.toLowerCase().startsWith(knownHeaderString.toLowerCase())) {
								isKnown = true;
								break;
							}
						}

						if (!isKnown) {
							// Truly unknown header, therefore interesting. Save for later use.
							unknownHeaders.append(separator + headerLine);
							separator = ", ";
						}
					}
				}
			} catch (Exception ee) {
				LOGGER.error("Error parsing HTTP headers", ee);
			}

		}

		if (request !is null) {
			// Still no media renderer recognized?
			if (request.getMediaRenderer() is null) {

				// Attempt 4: Not really an attempt; all other attempts to recognize
				// the renderer have failed. The only option left is to assume the
				// default renderer.
				request.setMediaRenderer(RendererConfiguration.getDefaultConf());
				LOGGER.trace("Using default media renderer: " ~ request.getMediaRenderer().getRendererName());

				if (userAgentString !is null && !userAgentString.opEquals("FDSSDP")) {
					// We have found an unknown renderer
					LOGGER.info("Media renderer was not recognized. Possible identifying HTTP headers: User-Agent: " ~ userAgentString
							+ ("".opEquals(unknownHeaders.toString()) ? "" : ", " ~ unknownHeaders.toString()));
					PMS.get().setRendererfound(request.getMediaRenderer());
				}
			} else {
				if (userAgentString !is null) {
					LOGGER.trace("HTTP User-Agent: " ~ userAgentString);
				}

				LOGGER.trace("Recognized media renderer: " ~ request.getMediaRenderer().getRendererName());
			}
		}

		if (HttpHeaders.getContentLength(nettyRequest) > 0) {
			byte[] data = new byte[cast(int) HttpHeaders.getContentLength(nettyRequest)];
			ChannelBuffer content = nettyRequest.getContent();
			content.readBytes(data);
			request.setTextContent(new String(data, "UTF-8"));
		}

		if (request !is null) {
			LOGGER.trace("HTTP: " ~ request.getArgument() ~ " / "
				~ request.getLowRange() ~ "-" ~ request.getHighRange());
		}

		writeResponse(e, request, ia);
	}

	/**
	 * Applies the IP filter to the specified internet address. Returns true
	 * if the address is not allowed and therefore should be filtered out,
	 * false otherwise.
	 * @param inetAddress The internet address to verify.
	 * @return True when not allowed, false otherwise.
	 */
	private bool filterIp(InetAddress inetAddress) {
		return !PMS.getConfiguration().getIpFiltering().allowed(inetAddress);
	}

	private void writeResponse(MessageEvent e, RequestV2 request, InetAddress ia) {
		// Decide whether to close the connection or not.
		bool close = HttpHeaders.Values.CLOSE.equalsIgnoreCase(nettyRequest.getHeader(HttpHeaders.Names.CONNECTION))
			|| nettyRequest.getProtocolVersion().opEquals(
			HttpVersion.HTTP_1_0)
			&& !HttpHeaders.Values.KEEP_ALIVE.equalsIgnoreCase(nettyRequest.getHeader(HttpHeaders.Names.CONNECTION));

		// Build the response object.
		HttpResponse response = null;
		if (request.getLowRange() != 0 || request.getHighRange() != 0) {
			response = new DefaultHttpResponse(
				/*request.isHttp10() ? HttpVersion.HTTP_1_0
				: */HttpVersion.HTTP_1_1,
				HttpResponseStatus.PARTIAL_CONTENT);
		} else {
			String soapAction = nettyRequest.getHeader("SOAPACTION");

			if (soapAction !is null && soapAction.contains("X_GetFeatureList")) {
				// Unsupported UPnP action
				response = new DefaultHttpResponse(
					HttpVersion.HTTP_1_1, HttpResponseStatus.INTERNAL_SERVER_ERROR);
			} else {
				response = new DefaultHttpResponse(
				/*request.isHttp10() ? HttpVersion.HTTP_1_0
				: */HttpVersion.HTTP_1_1, HttpResponseStatus.OK);
			}
		}
		
		StartStopListenerDelegate startStopListenerDelegate = new StartStopListenerDelegate(ia.getHostAddress());

		try {
			request.answer(response, e, close, startStopListenerDelegate);
		} catch (IOException e1) {
			LOGGER.trace("HTTP request V2 IO error: " ~ e1.getMessage());
			// note: we don't call stop() here in a finally block as
			// answer() is non-blocking. we only (may) need to call it
			// here in the case of an exception. it's a no-op if it's
			// already been called
			startStopListenerDelegate.stop();
		}
	}

	override
	public void exceptionCaught(ChannelHandlerContext ctx, ExceptionEvent e)
		{
		Channel ch = e.getChannel();
		Throwable cause = e.getCause();
		if (cast(TooLongFrameException)cause !is null) {
			sendError(ctx, HttpResponseStatus.BAD_REQUEST);
			return;
		}
		if (cause !is null && !cause.getClass().opEquals(ClosedChannelException._class) && !cause.getClass().opEquals(IOException._class)) {
			LOGGER._debug("Caught exception", cause);
		}
		if (ch.isConnected()) {
			sendError(ctx, HttpResponseStatus.INTERNAL_SERVER_ERROR);
		}
		e.getChannel().close();
	}

	private void sendError(ChannelHandlerContext ctx, HttpResponseStatus status) {
		HttpResponse response = new DefaultHttpResponse(
			HttpVersion.HTTP_1_1, status);
		response.setHeader(
			HttpHeaders.Names.CONTENT_TYPE, "text/plain; charset=UTF-8");
		response.setContent(ChannelBuffers.copiedBuffer(
			"Failure: " ~ status.toString() ~ "\r\n", Charset.forName("UTF-8")));

		// Close the connection as soon as the error message is sent.
		ctx.getChannel().write(response).addListener(ChannelFutureListener.CLOSE);
	}

	override
	public void channelOpen(ChannelHandlerContext ctx, ChannelStateEvent e)
		{
		// as seen in http://www.jboss.org/netty/community.html#nabble-td2423020
		super.channelOpen(ctx, e);
		if (group !is null) {
			group.add(ctx.getChannel());
		}
	}
	/* Uncomment to see channel events in the trace logs
	override
	public void handleUpstream(ChannelHandlerContext ctx, ChannelEvent e) {
	// Log all channel events.
	LOGGER.trace("Channel upstream event: " + e);
	super.handleUpstream(ctx, e);
	}
	 */
}
