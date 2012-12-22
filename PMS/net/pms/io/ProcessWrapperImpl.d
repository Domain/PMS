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
module net.pms.io.ProcessWrapperImpl;

import net.pms.PMS;
import net.pms.encoders.AviDemuxerInputStream;
import net.pms.util.ProcessUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class ProcessWrapperImpl : Thread , ProcessWrapper {
	private static immutable Logger LOGGER = LoggerFactory.getLogger!ProcessWrapperImpl();
	private String cmdLine;
	private Process process;
	private OutputConsumer stdoutConsumer;
	private OutputConsumer stderrConsumer;
	private OutputParams params;
	private bool destroyed;
	private String[] cmdArray;
	private bool nullable;
	private ArrayList/*<ProcessWrapper>*/ attachedProcesses;
	private BufferedOutputFile bo = null;
	private bool keepStdout;
	private bool keepStderr;
	private static int processCounter = 0;
	private bool success;

	override
	public String toString() {
		return super.getName();
	}

	public bool isSuccess() {
		return success;
	}

	public this(String cmdArray[], OutputParams params) {
		this(cmdArray, params, false, false);
	}

	public this(String cmdArray[], OutputParams params, bool keepOutput) {
		this(cmdArray, params, keepOutput, keepOutput);
	}

	public this(String cmdArray[], OutputParams params, bool keepStdout, bool keepStderr) {
		super();

		// Determine a suitable thread name for this process:
		// use the command name, but remove its path first.
		String threadName = cmdArray[0];

		if (threadName.indexOf("/") >= 0) {
			threadName = threadName.substring(threadName.lastIndexOf("/") + 1);
		}

		if (threadName.indexOf("\\") >= 0) {
			threadName = threadName.substring(threadName.lastIndexOf("\\") + 1);
		}

		setName(threadName ~ "-" ~ getProcessCounter());

		File exec = new File(cmdArray[0]);

		if (exec.isFile()) {
			cmdArray[0] = exec.getAbsolutePath();
		}

		this.cmdArray = cmdArray;
		StringBuilder sb = new StringBuilder("");

		for (int i = 0; i < cmdArray.length; i++) {
			if (i > 0) {
				sb.append(" ");
			}

			if (cmdArray[i] !is null && cmdArray[i].indexOf(" ") >= 0) {
				sb.append("\"" ~ cmdArray[i] ~ "\"");
			} else {
				sb.append(cmdArray[i]);
			}
		}

		cmdLine = sb.toString();
		this.params = params;
		this.keepStdout = keepStdout;
		this.keepStderr = keepStderr;
		attachedProcesses = new ArrayList<ProcessWrapper>();
	}

	private synchronized int getProcessCounter() {
		return processCounter++;
	}

	public void attachProcess(ProcessWrapper process) {
		attachedProcesses.add(process);
	}

	public void run() {
		ProcessBuilder pb = new ProcessBuilder(cmdArray);

		try {
			LOGGER._debug("Starting " ~ cmdLine);

			if (params.workDir !is null && params.workDir.isDirectory()) {
				pb.directory(params.workDir);
			}

			if (params.env !is null && !params.env.isEmpty()) {
				Map/*<String,String>*/ environment = pb.environment();
				// actual name of system path var is case-sensitive
				String sysPathKey = PMS.get().isWindows() ? "Path" : "PATH";
				// as is Map
				String PATH = params.env.containsKey("PATH") ? params.env.get("PATH") :
					params.env.containsKey("path") ? params.env.get("path") :
					params.env.containsKey("Path") ? params.env.get("Path") : null;

				if (PATH !is null) {
					PATH ~= (File.pathSeparator ~ environment.get(sysPathKey));
				}

				environment.putAll(params.env);

				if (PATH !is null) {
					environment.put(sysPathKey, PATH);
				}
			}

			// XXX A cleaner way to execute short-running commands (e.g. vlc -version)
			// is being developed. When that's done, this class can be used solely
			// for the long-running tasks i.e. transcodes. At that point, we won't need
			// separate stdout and stderr and can merge them by uncommenting the
			// following line:
			// pb.redirectErrorStream(true);
			process = pb.start();
			PMS.get().currentProcesses.add(process);

			stderrConsumer = keepStderr
				? new OutputTextConsumer(process.getErrorStream(), true)
				: new OutputTextLogger(process.getErrorStream());
			stderrConsumer.start();
			stdoutConsumer = null;

			if (params.input_pipes[0] !is null) {
				LOGGER._debug("Reading pipe: " ~ params.input_pipes[0].getInputPipe());
				bo = params.input_pipes[0].getDirectBuffer();

				if (bo is null || params.losslessaudio || params.lossyaudio || params.no_videoencode) {
					InputStream _is = params.input_pipes[0].getInputStream();

					if (params.avidemux) {
						_is = new AviDemuxerInputStream(_is, params, attachedProcesses);
					}

					stdoutConsumer = new OutputBufferConsumer(_is, params);
					bo = stdoutConsumer.getBuffer();
				}

				bo.attachThread(this);
				(new OutputTextLogger(process.getInputStream())).start();
			} else if (params.log) {
				stdoutConsumer = keepStdout
					? new OutputTextConsumer(process.getInputStream(), true)
					: new OutputTextLogger(process.getInputStream());
			} else {
				stdoutConsumer = new OutputBufferConsumer(process.getInputStream(), params);
				bo = stdoutConsumer.getBuffer();
				bo.attachThread(this);
			}

			if (stdoutConsumer !is null) {
				stdoutConsumer.start();
			}

			if (params.stdin !is null) {
				params.stdin.push(process.getOutputStream());
			}

			Integer pid = ProcessUtil.getProcessID(process);

			if (pid !is null) {
				LOGGER._debug("Unix process ID (%s): %s", cmdArray[0], pid);
			}

			ProcessUtil.waitFor(process);

			// wait up to a second for the stderr consumer thread to finish
			try {
				if (stderrConsumer !is null) {
					stderrConsumer.join(1000);
				}
			} catch (InterruptedException e) { }

			// wait up to a second for the stdout consumer thread to finish
			try {
				if (stdoutConsumer !is null) {
					stdoutConsumer.join(1000);
				}
			} catch (InterruptedException e) { }
		} catch (Exception e) {
			LOGGER.error("Error initializing process: ", e);
			stopProcess();
		} finally {
			try {
				if (bo !is null) {
					bo.close();
				}
			} catch (IOException ioe) {
				LOGGER._debug("Error closing buffered output file", ioe.getMessage());
			}

			if (!destroyed && !params.noexitcheck) {
				try {
					success = true;
					if (process !is null && process.exitValue() != 0) {
						LOGGER.info("Process %s has a return code of {}! Maybe an error occurred... check the log file", cmdArray[0], process.exitValue());
						success = false;
					}
				} catch (IllegalThreadStateException itse) {
					LOGGER.error("Error reading process exit value", itse);
				}
			}

			if (attachedProcesses !is null) {
				foreach (ProcessWrapper pw ; attachedProcesses) {
					if (pw !is null) {
						pw.stopProcess();
					}
				}
			}

			PMS.get().currentProcesses.remove(process);
		}
	}

	/**
	 * Same as {@link #start()}, merely making the intention explicit in the
	 * method name.
	 * @see #runInSameThread()
	 */
	public void runInNewThread() {
		this.start();
	}

	/**
	 * Same as {@link #run()}, merely making the intention explicit in the
	 * method name.
	 * @see #runInNewThread()
	 */
	public void runInSameThread() {
		this.run();
	}

	public InputStream getInputStream(long seek) {
		if (bo !is null) {
			return bo.getInputStream(seek);
		} else if (stdoutConsumer !is null && stdoutConsumer.getBuffer() !is null) {
			return stdoutConsumer.getBuffer().getInputStream(seek);
		}

		return null;
	}

	public List/*<String>*/ getOtherResults() {
		if (stdoutConsumer is null) {
			return null;
		}

		try {
			stdoutConsumer.join(1000);
		} catch (InterruptedException e) { }

		return stdoutConsumer.getResults();
	}

	public List/*<String>*/ getResults() {
		try {
			stderrConsumer.join(1000);
		} catch (InterruptedException e) { }

		return stderrConsumer.getResults();
	}

	public synchronized void stopProcess() {
		if (!destroyed) {
			destroyed = true;
			if (process !is null) {
				Integer pid = ProcessUtil.getProcessID(process);

				if (pid !is null) {
					LOGGER._debug("Stopping Unix process " ~ pid.toString() ~ ": " ~ this);
				} else {
					LOGGER._debug("Stopping process: " ~ this.toString());
				}

				ProcessUtil.destroy(process);
			}

			if (attachedProcesses !is null) {
				foreach (ProcessWrapper pw ; attachedProcesses) {
					if (pw !is null) {
						pw.stopProcess();
					}
				}
			}

			if (stdoutConsumer !is null && stdoutConsumer.getBuffer() !is null) {
				stdoutConsumer.getBuffer().reset();
			}
		}
	}

	public bool isDestroyed() {
		return destroyed;
	}

	public bool isReadyToStop() {
		return nullable;
	}

	public void setReadyToStop(bool nullable) {
		if (nullable != this.nullable) {
			LOGGER.trace("Ready to Stop: " ~ nullable);
		}

		this.nullable = nullable;
	}
}
