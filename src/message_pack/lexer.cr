class MessagePack::Lexer
  getter token
  getter current_byte

  def self.new(string : String)
    new MemoryIO.new(string)
  end

  def self.new(slice : Slice(UInt8))
    io = MemoryIO.new
    io.write(slice)
    io.rewind
    new(io)
  end

  def initialize(io : IO)
    @io = io
    @token = Token.new
    @byte_number = 0
    @current_byte = 0
    @eof = false
    next_byte
  end

  def next_token
    @token.byte_number = @byte_number

    if @eof
      @token.type = :EOF
      return @token
    end

    case current_byte
    when 0xC0
      next_byte(:nil, 0)
    when 0xC2
      next_byte(:false, 0)
    when 0xC3
      next_byte(:true, 0)
    when 0xA0..0xBF
      consume_string(current_byte - 0xA0)
    when 0xE0..0xFF
      @token.type = :INT
      @token.int_value = current_byte.to_i8
      next_byte
    when 0x00..0x7f
      @token.type = :UINT
      @token.uint_value = current_byte
      next_byte
    when 0x80..0x8f
      next_byte(:HASH, current_byte - 0x80)
    when 0x90..0x9f
      next_byte(:ARRAY, current_byte - 0x90)
    when 0xC4
      consume_string(next_byte)
    when 0xC5
      consume_string(read_uint16)
    when 0xC6
      consume_string(read_uint32)
    when 0xCA
      consume_float(read_float32)
    when 0xCB
      consume_float(read_float64)
    when 0xCC
      consume_uint(read_uint8)
    when 0xCD
      consume_uint(read_uint16)
    when 0xCE
      consume_uint(read_uint32)
    when 0xCF
      consume_uint(read_uint64)
    when 0xD0
      consume_int(read_int8)
    when 0xD1
      consume_int(read_int16)
    when 0xD2
      consume_int(read_int32)
    when 0xD3
      consume_int(read_int64)
    when 0xD9
      consume_string(read_uint8)
    when 0xDA
      consume_string(read_uint16)
    when 0xDB
      consume_string(read_uint32)
    when 0xDC
      next_byte(:ARRAY, read_uint16)
    when 0xDD
      next_byte(:ARRAY, read_uint32)
    when 0xDE
      next_byte(:HASH, read_uint16)
    when 0xDF
      next_byte(:HASH, read_uint32)
    when unexpected_byte
    end

    @token
  end

  private def next_byte
    @byte_number += 1
    byte = @io.read_byte

    unless byte
      @eof = true
    end

    @current_byte = byte || 0.to_u8
  end

  private def next_bytes(size)
    @byte_number += size

    bytes = Slice(UInt8).new(size)
    @io.read(bytes)
    bytes
  end

  private def next_byte(type, size)
    @token.type = type
    @token.size = size
    next_byte
  end

  private def consume_uint(value)
    @token.type = :UINT
    @token.uint_value = value
    next_byte
  end

  private def consume_int(value)
    @token.type = :INT
    @token.int_value = value
    next_byte
  end

  private def consume_float(value)
    @token.type = :FLOAT
    @token.float_value = value
    next_byte
  end

  private def consume_string(size)
    @token.type = :STRING
    @token.string_value = String.new(consume_slice(size))
    next_byte
  end

  private def consume_slice(size)
    slice = Slice(UInt8).new(size.to_i32)
    @io.read(slice)
    @byte_number += size
    slice
  end

  private def read_uint8
    next_byte
  end

  private def read_uint16
    b1, b2 = next_bytes(2)
    tuple16 = {b2, b1}
    (pointerof(tuple16) as UInt16*).value
  end

  private def read_uint32
    b1, b2, b3, b4 = next_bytes(4)
    tuple = {b4, b3, b2, b1}
    (pointerof(tuple) as UInt32*).value
  end

  private def read_uint64
    b1, b2, b3, b4, b5, b6, b7, b8 = next_bytes(8)
    tuple64 = {b8, b7, b6, b5, b4, b3, b2, b1}
    (pointerof(tuple64) as UInt64*).value
  end

  private def read_int8
    next_byte.to_i8
  end

  private def read_int16
    b1, b2 = next_bytes(2)
    tuple = {b2, b1}
    (pointerof(tuple) as Int16*).value
  end

  private def read_int32
    b1, b2, b3, b4 = next_bytes(4)
    tuple = {b4, b3, b2, b1}
    (pointerof(tuple) as Int32*).value
  end

  private def read_int64
    b1, b2, b3, b4, b5, b6, b7, b8 = next_bytes(8)
    tuple = {b8, b7, b6, b5, b4, b3, b2, b1}
    (pointerof(tuple) as Int64*).value
  end

  private def read_float32
    b1, b2, b3, b4 = next_bytes(4)
    tuple = {b4, b3, b2, b1}
    (pointerof(tuple) as Float32*).value
  end

  private def read_float64
    b1, b2, b3, b4, b5, b6, b7, b8 = next_bytes(8)
    tuple = {b8, b7, b6, b5, b4, b3, b2, b1}
    (pointerof(tuple) as Float64*).value
  end

  private def unexpected_byte(byte = current_byte)
    raise "unexpected byte '#{byte}'"
  end

  private def raise(msg)
    ::raise UnpackException.new(msg, @byte_number)
  end
end
