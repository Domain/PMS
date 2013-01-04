/*
 * PS3 Media Server, for streaming any medias to your PS3.
 * Copyright (C) 2011 G. Zsombor
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
module net.pms.network.SpeedStats;

import net.pms.PMS;
import net.pms.io.OutputParams;
import net.pms.io.ProcessWrapperImpl;
import net.pms.io.SystemUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.InetAddress;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
//import java.util.concurrent.all;

/**
 * Network speed tester class. This can be used in an asynchronous way, as it returns Future objects.
 * 
 * Future<Integer> speed = SpeedStats.getInstance().getSpeedInMBits(addr);
 * 
 *  @see Future
 * 
 * @author zsombor <gzsombor@gmail.com>
 *
 */
public class SpeedStats {
	private static SpeedStats instance = new SpeedStats();
	private static ExecutorService executor = Executors.newCachedThreadPool();
	public static SpeedStats getInstance() {
		return instance;
	}

	private static immutable Logger LOGGER = LoggerFactory.getLogger!SpeedStats();

	private Map/*<String, Future<Integer>>*/ speedStats = new HashMap/*<String, Future<Integer>>*/();

	/**
	 * Return the network throughput for the given IP address in MBits. It is calculated in the background, and cached,
	 * so only a reference is given to the result, which can be retrieved by calling the get() method on it.
	 * @param addr
	 * @return  The network throughput
	 */
	public Future/*<Integer>*/ getSpeedInMBits(InetAddress addr, String rendererName) {
		synchronized(speedStats) { 
			Future/*<Integer>*/ value = speedStats.get(addr.getHostAddress());
			if (value !is null) {
				return value;
			}
			value = executor.submit(new MeasureSpeed(addr, rendererName));
			speedStats.put(addr.getHostAddress(), value);
			return value;
		}
	}

	class MeasureSpeed : Callable/*<Integer>*/ {
		InetAddress addr;
		String rendererName;

		public this(InetAddress addr, String rendererName) {
			this.addr = addr;
			this.rendererName = rendererName !is null ? rendererName : "Unknown";
		}

		override
		public Integer call() {
			try {
				return doCall();
			} catch (Exception e) {
				logger.warn("Error measuring network throughput : " ~ e.getMessage(), e);
				throw e;
			}
		}

		private Integer doCall() {
			String ip = addr.getHostAddress();
			logger.info("Checking IP: " ~ ip ~ " for " ~ rendererName);
			// calling the canonical host name the first time is slow, so we call it in a separate thread
			String hostname = addr.getCanonicalHostName();
			synchronized(speedStats) {
				Future/*<Integer>*/ otherTask = speedStats.get(hostname);
				if (otherTask !is null) {
					// wait a little bit
					try {
						// probably we are waiting for ourself to finish the work...
						Integer value = otherTask.get(100, TimeUnit.MILLISECONDS);
						// if the other task already calculated the speed, we get the result,
						// unless we do it now 
						if (value !is null) {
							return value;
						}
					} catch (TimeoutException e) {
						logger.trace("We couldn't get the value based on the canonical name");
					}
				}
			}

			
			if (!ip.opEquals(hostname)) {
				logger.info("Renderer " ~ rendererName ~ " found on this address: " ~ hostname ~ " (" ~ ip ~ ")");
			} else {
				logger.info("Renderer " ~ rendererName ~ " found on this address: " ~ ip);
			}

			// let's get that speed
			OutputParams op = new OutputParams(null);
			op.log = true;
			op.maxBufferSize = 1;
			SystemUtils sysUtil = PMS.get().getRegistry();
			immutable ProcessWrapperImpl pw = new ProcessWrapperImpl(sysUtil.getPingCommand(addr.getHostAddress(), 3, 64000), op,
					true, false);
			Runnable r = dgRunnable( {
					try {
						Thread.sleep(2000);
					} catch (InterruptedException e) {
					}
					pw.stopProcess();
			});

			Thread failsafe = new Thread(r, "SpeedStats Failsafe");
			failsafe.start();
			pw.runInSameThread();
			List/*<String>*/ ls = pw.getOtherResults();
			int time = 0;
			int c = 0;

			foreach (String line ; ls) {
				int msPos = line.indexOf("ms");

				if (msPos > -1) {
					String timeString = line.substring(line.lastIndexOf("=", msPos) + 1, msPos).trim();
					try {
						time += Double.parseDouble(timeString);
						c++;
					} catch (NumberFormatException e) {
						// no big deal
						logger._debug("Could not parse time from \"" ~ timeString ~ "\"");
					}
				}
			}
			if (c > 0) {
				time = time / c;
			}

			if (time > 0) {
				int speedInMbits = 1024 / time;
				logger.info("Address " ~ addr ~ " has an estimated network speed of: " ~ speedInMbits.toString() ~ " Mb/s");
				synchronized(speedStats) {
					CompletedFuture/*<Integer>*/ result = new CompletedFuture/*<Integer>*/(speedInMbits);
					// update the statistics with a computed future value
					speedStats.put(ip, result);
					speedStats.put(hostname, result);
				}
				return speedInMbits;
			}
			return -1;
		}
	}

	static class CompletedFuture(X) : Future/*<X>*/ {
		X value;
		
		public this(X value) {
			this.value = value;
		}

		override
		public bool cancel(bool mayInterruptIfRunning) {
			return false;
		}

		override
		public bool isCancelled() {
			return false;
		}

		override
		public bool isDone() {
			return true;
		}

		override
		public X get() {
			return value;
		}

		override
		public X get(long timeout, TimeUnit unit) {
			return value;
		}
	}
}
