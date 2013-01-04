module net.pms.dlna.Range;

public abstract class Range : Cloneable {

	public abstract void limit(Range range);

	public abstract bool isByteRange();

	public bool isTimeRange() {
		return !isByteRange();
	}

	public abstract bool isStartOffsetAvailable();

	public abstract bool isEndLimitAvailable();

	public double getDuration() {
		return 0;
	}

	public Byte asByteRange() {
		throw new RuntimeException("Unable to convert to ByteRange:" ~ this.toString());
	}

	/**
	 * @return a Range.Time object, which is bounded if this is already a bounded Range.Time object
	 */
	public Time createTimeRange() {
		return new Time(null, null);
	}

	public static Range create(long lowRange, long highRange, Double timeseek, Double timeRangeEnd) {
		if (lowRange > 0 || highRange > 0) {
			return new Range.Byte(lowRange, highRange);
		}
		return new Range.Time(timeseek, timeRangeEnd);
	}

	public static class Time : Range , Cloneable {
		private Double start;
		private Double end;

		public this() {
		}

		public this(Double start, Double end) {
			this.start = start;
			this.end = end;
		}

		/**
		 * @return the start
		 */
		public Double getStart() {
			return start;
		}

		public double getStartOrZero() {
			return start !is null ? start : 0;
		}

		/**
		 * @param start the start to set
		 */
		public Time setStart(Double start) {
			this.start = start;
			return this;
		}

		/**
		 * Move the start position by amount, if the start position exists.
		 * @param amount
		 */
		public void rewindStart(double amount) {
			if (this.start !is null) {
				if (this.start > amount) {
					this.start = this.start - amount;
				} else {
					this.start = 0;
				}
			}
		}

		/**
		 * @return the end
		 */
		public Double getEnd() {
			return end;
		}

		public double getEndOrZero() {
			return end !is null ? end : 0;
		}

		/**
		 * @param end the end to set
		 */
		public Time setEnd(Double end) {
			this.end = end;
			return this;
		}

		override
		public void limit(Range range) {
			limitTime(cast(Time) range);
		}

		override
		public bool isByteRange() {
			return false;
		}

		private void limitTime(Time range) {
			if (range.start !is null) {
				if (start !is null) {
					start = Math.max(start, range.start);
				}
				if (end !is null) {
					end = Math.max(end, range.start);
				}
			}
			if (range.end !is null) {
				if (start !is null) {
					start = Math.min(start, range.end);
				}
				if (end !is null) {
					end = Math.min(end, range.end);
				}
			}
		}

		/* (non-Javadoc)
		 * @see java.lang.Object#toString()
		 */
		override
		public String toString() {
			return "TimeRange [start=" ~ start ~ ", end=" ~ end ~ "]";
		}

		override
		public bool isStartOffsetAvailable() {
			return start !is null;
		}

		override
		public bool isEndLimitAvailable() {
			return end !is null;
		}

		override
		public double getDuration() {
			return start !is null ? end - start : (end !is null ? end : 0);
		}

		override
		public Time createTimeRange() {
			return new Time(start, end);
		}

		public Byte createScaledRange(long scale) {
			return new Byte(start !is null ? cast(long) (scale * start) : null, end !is null ? cast(long) (scale * end) : null);
		}
	}

	public static class Byte : Range , Cloneable {
		private Long start;
		private Long end;

		public this() {
		}

		public this(Long start, Long end) {
			this.start = start;
			this.end = end;
		}

		override
		public void limit(Range range) {
			limitTime(cast(Byte) range);
		}

		override
		public bool isByteRange() {
			return true;
		}

		/**
		 * @return the start
		 */
		public Long getStart() {
			return start;
		}

		/**
		 * @param start the start to set
		 */
		public Byte setStart(Long start) {
			this.start = start;
			return this;
		}

		/**
		 * @return the end
		 */
		public Long getEnd() {
			return end;
		}

		/**
		 * @param end the end to set
		 */
		public Byte setEnd(Long end) {
			this.end = end;
			return this;
		}

		private void limitTime(Byte range) {
			if (range.start !is null) {
				if (start !is null) {
					start = Math.max(start, range.start);
				}
				if (end !is null) {
					end = Math.max(end, range.start);
				}
			}
			if (range.end !is null) {
				if (start !is null) {
					start = Math.min(start, range.end);
				}
				if (end !is null) {
					end = Math.min(end, range.end);
				}
			}
		}

		/* (non-Javadoc)
		 * @see java.lang.Object#toString()
		 */
		override
		public String toString() {
			return "ByteRange [start=" ~ start ~ ", end=" ~ end ~ "]";
		}

		override
		public bool isStartOffsetAvailable() {
			return start !is null;
		}

		override
		public bool isEndLimitAvailable() {
			return end !is null;
		}

		override
		public Byte asByteRange() {
			return this;
		}

	}

}
