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
module net.pms.io.ProcessWrapperLiteImpl;

import net.pms.util.ProcessUtil;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;

public class ProcessWrapperLiteImpl : ProcessWrapper {
	private Process p;

	public this(Process p) {
		this.p = p;
	}

	override
	public InputStream getInputStream(long seek) {
		return null;
	}

	override
	public ArrayList/*<String>*/ getResults() {
		return null;
	}

	override
	public bool isDestroyed() {
		return false;
	}

	override
	public void runInNewThread() {
	}

	override
	public bool isReadyToStop() {
		return false;
	}

	override
	public void setReadyToStop(bool nullable) {
	}

	override
	public void stopProcess() {
		ProcessUtil.destroy(p);
	}
}
