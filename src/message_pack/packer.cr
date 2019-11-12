struct MessagePack::Packer
  def self.new(io : IO = IO::Memory.new)
    packer = new(io)
    yield packer
    packer
  end

  def initialize(@io : IO = IO::Memory.new)
  end

  def write(value : Nil)
    write_byte(0xC0)
    self
  end

  def write(value : Bool)
    write_byte(value ? 0xC3_u8 : 0xC2_u8)
    self
  end

  def write_string_start(bytesize)
    case bytesize
    when (0x00..0x1F)
      write_byte(0xA0_u8 + bytesize.to_u8)
    when (0x0000..0xFF)
      write_byte(0xD9)
      write_value(bytesize.to_u8)
    when (0x0000..0xFFFF)
      write_byte(0xDA)
      write_value(bytesize.to_u16)
    when (0x00000000..0xFFFFFFFF)
      write_byte(0xDB)
      write_value(bytesize.to_u32)
    else
      raise PackError.new("invalid length")
    end
    self
  end

  def write_binary_start(bytesize)
    case bytesize
    when (0x0000..0xFF)
      # bin8
      write_byte(0xC4)
      write_value(bytesize.to_u8)
    when (0x0000..0xFFFF)
      # bin16
      write_byte(0xC5)
      write_value(bytesize.to_u16)
    when (0x00000000..0xFFFFFFFF)
      # bin32
      write_byte(0xC6)
      write_value(bytesize.to_u32)
    else
      raise PackError.new("invalid length")
    end
    self
  end

  def write(value : String)
    write_string_start(value.bytesize)
    write_slice(value.to_slice)
    self
  end

  def write(value : Bytes)
    write_binary_start(value.bytesize)
    write_slice(value)
    self
  end

  def write(value : Symbol)
    write(value.to_s)
  end

  def write(value : Float32 | Float64)
    case value
    when Float32
      write_byte(0xCA)
    when Float64
      write_byte(0xCB)
    end
    write_value(value)
    self
  end

  def write(value : Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64)
    if value >= 0
      if 0x7F.to_u8 >= value
        write_byte(value.to_u8)
      elsif UInt8::MAX >= value
        write_byte(0xCC)
        write_byte(value.to_u8)
      elsif UInt16::MAX >= value
        write_byte(0xCD)
        write_value(value.to_u16)
      elsif UInt32::MAX >= value
        write_byte(0xCE)
        write_value(value.to_u32)
      else
        write_byte(0xCF)
        write_value(value.to_u64)
      end
    else
      if -0x20.to_i8 <= value
        v = value.to_i8
        write_byte(v.to_u8!)
      elsif Int8::MIN <= value
        write_byte(0xD0)
        v = value.to_i8
        write_byte(v.to_u8!)
      elsif Int16::MIN <= value
        write_byte(0xD1)
        write_value(value.to_i16)
      elsif Int32::MIN <= value
        write_byte(0xD2)
        write_value(value.to_i32)
      else
        write_byte(0xD3)
        write_value(value.to_i64)
      end
    end
    self
  end

  def write(value : Hash)
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
      write_byte(0x80_u8 + length.to_u8)
    when (0x0000..0xFFFF)
      write_byte(0xDE)
      write_value(length.to_u16)
    when (0x00000000..0xFFFFFFFF)
      write_byte(0xDF)
      write_value(length.to_u32)
    else
      raise PackError.new("invalid length")
    end
    self
  end

  def write(value : Array)
    write_array_start(value.size)
    value.each { |item| self.write(item) }
    self
  end

  def write_array_start(length)
    case length
    when (0x00..0x0F)
      write_byte(0x90_u8 + length.to_u8)
    when (0x0000..0xFFFF)
      write_byte(0xDC)
      write_value(length.to_u16)
    when (0x00000000..0xFFFFFFFF)
      write_byte(0xDD)
      write_value(length.to_u32)
    else
      raise PackError.new("invalid length")
    end
    self
  end

  def write(value : Tuple)
    write_array_start(value.size)
    value.each { |item| self.write(item) }
    self
  end

  def write_ext_start(bytesize)
    case bytesize
    when 1
      write_byte(0xD4)
    when 2
      write_byte(0xD5)
    when 4
      write_byte(0xD6)
    when 8
      write_byte(0xD7)
    when 16
      write_byte(0xD8)
    when 0x00..0xFF
      write_byte(0xC7)
      write_byte(bytesize.to_u8)
    when 0x0000..0xFFFF
      write_byte(0xC8)
      write_value(bytesize.to_u16)
    when 0x00000000..0xFFFFFFFF
      write_byte(0xC9)
      write_value(bytesize.to_u32)
    else
      raise PackError.new("invalid length")
    end
    self
  end

  def write_ext(type_id : Int8, bytes : Bytes)
    write_ext_start(bytes.size)
    write_byte(type_id.to_u8!)
    write_slice(bytes.to_slice)
  end

  def write_ext(type_id : Int8)
    io = IO::Memory.new
    yield(io)
    write_ext(type_id, io.to_slice)
  end

  private def write_byte(byte : UInt8)
    @io.write_byte(byte)
  end

  private def write_value(value)
    @io.write_bytes(value, IO::ByteFormat::BigEndian)
  end

  private def write_slice(slice)
    @io.write(slice)
  end

  def to_slice
    io = @io
    if io.responds_to?(:to_slice)
      io.to_slice
    else
      raise Error.new("to slice not implemented for io type: #{typeof(io)}")
    end
  end

  def to_s
    @io.to_s
  end

  def bytes
    @io.to_s.bytes
  end
end
