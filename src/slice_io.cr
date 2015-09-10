class SliceIO(T)
  include IO

  getter buffer
  getter bytesize

  def initialize(@buffer : Slice(T))
    @bytesize = @buffer.length
    @pos = 0
  end

  def read(slice : Slice(UInt8), count)
    count = Math.min(count, @bytesize - @pos)
    slice.copy_from(@buffer.to_unsafe + @pos, count)
    @pos += count
    count
  end

  def read(slice : Slice(UInt8))
    read(slice, slice.length)
  end

  def write(slice : Slice(UInt8), count)
    slice.copy_to(@buffer.to_unsafe + @bytesize, count)
    @bytesize += count

    count
  end

  def write(slice : Slice(UInt8))
    write(slice, slice.length)
  end

  def clear
    @bytesize = 0
  end

  def empty?
    @bytesize == 0
  end

  def rewind
    @pos = 0
    self
  end

  def to_s
    Slice(T).new @buffer, @bytesize
  end

  def to_s(io)
    io.write @buffer
  end
end
