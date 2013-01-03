module org.serviio.library.local.metadata.extractor.embedded.h264.BufferWrapper;

import java.io.IOException;

public abstract interface BufferWrapper
{
  public abstract int readUInt8()
    throws IOException;

  public abstract int readUInt24()
    throws IOException;

  public abstract String readIso639()
    throws IOException;

  public abstract String readString()
    throws IOException;

  public abstract long position()
    throws IOException;

  public abstract long remaining()
    throws IOException;

  public abstract String readString(int paramInt)
    throws IOException;

  public abstract long skip(long paramLong)
    throws IOException;

  public abstract void position(long paramLong)
    throws IOException;

  public abstract int read(byte[] paramArrayOfByte)
    throws IOException;

  public abstract BufferWrapper getSegment(long paramLong1, long paramLong2)
    throws IOException;

  public abstract long readUInt32()
    throws IOException;

  public abstract int readInt32()
    throws IOException;

  public abstract long readUInt64()
    throws IOException;

  public abstract byte readByte()
    throws IOException;

  public abstract int read()
    throws IOException;

  public abstract int readUInt16()
    throws IOException;

  public abstract long size();

  public abstract byte[] read(int paramInt)
    throws IOException;

  public abstract double readFixedPoint1616()
    throws IOException;

  public abstract float readFixedPoint88()
    throws IOException;

  public abstract int readUInt16BE()
    throws IOException;

  public abstract long readUInt32BE()
    throws IOException;

  public abstract int readBits(int paramInt)
    throws IOException;

  public abstract int getReadBitsRemaining();
}

/* Location:           D:\Program Files\Serviio\lib\serviio.jar
 * Qualified Name:     org.serviio.library.local.metadata.extractor.embedded.h264.BufferWrapper
 * JD-Core Version:    0.6.2
 */