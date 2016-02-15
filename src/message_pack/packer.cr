class MessagePack::Packer
  def self.new(io = MemoryIO.new : IO)
    packer = new(io)
    yield packer
    packer
  end

  def initialize(io = MemoryIO.new : IO)
    @io = io
  end

  def write(value : Nil | Bool)
    case value
    when Nil
      write_byte(0xC0)
    when true
      write_byte(0xC3)
    when false
      write_byte(0xC2)
    end
    self
  end

  def write(value : String)
    bytesize = value.bytesize
    case bytesize
    when (0x00..0x1F)
      # fixraw
      write_byte(0xA0 + bytesize)
      write_slice(value.to_slice)
    when (0x0000..0xFFFF)
      # raw16
      write_byte(0xDA)
      write_value(bytesize.to_u16)
      write_slice(value.to_slice)
    when (0x00000000..0xFFFFFFFF)
      # raw32
      write_byte(0xDB)
      write_value(bytesize.to_u32)
      write_slice(value.to_slice)
    else
      raise("invalid length")
    end
    self
  end

  def write(value : Symbol)
    write(value.to_s)
  end

  def write(value : Float32 | Float64 | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64)
    case value
    when Float32
      write_byte(0xCA)
    when Float64
      write_byte(0xCB)
    when UInt8
      case value
      when 0x00..0x7f
        # positive fixnum
      else
        write_byte(0xCC)
      end
    when UInt16
      write_byte(0xCD)
    when UInt32
      write_byte(0xCE)
    when UInt64
      write_byte(0xCF)
    when Int8
      case value
      when (-0x20..0x7F)
        # positive fixnum, negative fixnum
      else
        write_byte(0xD0)
      end
    when Int16
      write_byte(0xD1)
    when Int32
      write_byte(0xD2)
    when Int64
      write_byte(0xD3)
    end
    write_value(value)
    self
  end

  def write(value : Hash(Type, Type))
    write_hash_start(value.size)

    value.each do |key, value|
      self.write(key)
      self.write(value)
    end
    self
  end

  def write_hash_start(length)
    case length
    when (0x00..0x0F)
      write_byte(0x80 + length)
    when (0x0000..0xFFFF)
      write_byte(0xDE)
      write_value(length.to_u16)
    when (0x00000000..0xFFFFFFFF)
      write_byte(0xDF)
      write_value(length.to_u32)
    else
      raise("invalid length")
    end
    self
  end

  def write(value : Array(Type))
    write_array_start(value.size)

    value.each do |item|
      self.write(item)
    end
    self
  end

  def write_array_start(length)
    case length
    when (0x00..0x0F)
      write_byte(0x90 + length)
    when (0x0000..0xFFFF)
      write_byte(0xDC)
      write_value(length.to_u16)
    when (0x00000000..0xFFFFFFFF)
      write_byte(0xDD)
      write_value(length.to_u32)
    else
      raise("invalid length")
    end
    self
  end

  def write(value : Tuple)
    write_array_start(value.size)
    value.each do |item|
      self.write(item)
    end
    self
  end

  private def write_byte(byte)
    @io.write_byte(byte.to_u8)
  end

  private def write_value(value)
    @io.write_bytes(value, IO::ByteFormat::BigEndian)
  end

  private def write_slice(slice)
    IO.copy(MemoryIO.new(slice), @io)
  end

  def to_slice
    @io.to_slice
  end

  def to_s
    @io.to_s
  end

  def bytes
    @io.to_s.bytes
  end
end
