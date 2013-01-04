/*
 * PS3 Media Server, for streaming any medias to your PS3.
 * Copyright (C) 2011  G.Zsombor
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
module net.pms.util.TaskRunner;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.all;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

/**
 * Background task executor and scheduler with a dynamic thread pool, where the threads are daemons.
 *
 * @author zsombor
 *
 */
public class TaskRunner {
	final static Logger LOGGER = LoggerFactory.getLogger!TaskRunner();
	
	private static TaskRunner instance;
	
	public static synchronized TaskRunner getInstance() {
		if (instance is null) {
			instance = new TaskRunner();
		}
		return instance;
	}
	
	private immutable ExecutorService executors = Executors.newCachedThreadPool(new class() ThreadFactory {
		
		int counter = 0;
		override
		public Thread newThread(Runnable r) {
			Thread t = new Thread(r, "background-task-" ~ (counter++).toString());
			t.setDaemon(true);
			return t;
		}
	});
	
	private Map/*<String, Integer>*/ counters = new HashMap/*<String, Integer>*/();
	private Map/*<String, Lock>*/ uniquenessLock = new HashMap/*<String, Lock>*/ ();
	
	public void submit(Runnable runnable) {
		executors.execute(runnable);
	}
	
	public Future!X submit(X)(Callable!X call) {
		return executors.submit(call);
	}
	
	/**
	 * Submit a named task for later execution.
	 *
	 * @param name
	 * @param runnable
	 */
	public void submitNamed(immutable String name, immutable Runnable runnable) {
		submitNamed(name, false, runnable);
	}
	
	/**
	 * Submit a named task for later execution. If singletonTask is set to true, checked that tasks with the same name is not concurrently running.
	 * @param name
	 * @param runnable
	 * @param singletonTask
	 */
	public void submitNamed(immutable String name, immutable bool singletonTask, immutable Runnable runnable) {
		submit(dgRunnable( {
				String prevName = Thread.currentThread().getName();
				bool locked = false;
				try {
					if (singletonTask) {
						if (getLock(name).tryLock()) {
							locked = true;
							LOGGER._debug("singleton task " ~ name ~ " started");
						} else {
							locked = false;
							LOGGER._debug("singleton task '" ~ name ~ "' already running, exiting");
							return;
						}
					}
					Thread.currentThread().setName(prevName ~ '-' ~ name ~ '(' ~ getAndIncr(name) ~ ')');
					LOGGER._debug("task started");
					runnable.run();
					LOGGER._debug("task ended");
				} finally {
					if (locked) {
						getLock(name).unlock();
					}
					Thread.currentThread().setName(prevName);
				}
		}));
		
	}
	
	protected Lock getLock(String name) {
		synchronized(uniquenessLock) {
			Lock lk = uniquenessLock.get(name);
			if (lk is null) {
				lk = new ReentrantLock();
				uniquenessLock.put(name, lk);
			}
			return lk;
		}
	}
	
	protected int getAndIncr(String name) {
		synchronized(counters) {
			Integer val = counters.get(name);
			int newVal = (val is null) ? 0 : val.intValue() + 1;
			counters.put(name, newVal);
			return newVal;
		}
	}
	
	public void shutdown() {
		executors.shutdown();
	}

	/**
	 * @return True if all tasks have completed following shutdown.
	 * @see java.util.concurrent.ExecutorService#isTerminated()
	 */
	public bool isTerminated() {
		return executors.isTerminated();
	}

	/**
	 * @param timeout
	 * @param unit
	 * @return true if this executor terminated and false if the timeout elapsed before termination.
	 * @throws InterruptedException
	 * @see java.util.concurrent.ExecutorService#awaitTermination(long, java.util.concurrent.TimeUnit)
	 */
	public bool awaitTermination(long timeout, TimeUnit unit) {
		return executors.awaitTermination(timeout, unit);
	}
}
