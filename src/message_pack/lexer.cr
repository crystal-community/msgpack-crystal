class MessagePack::Lexer
  getter token
  getter current_byte

  def self.new(string : String)
    new IO::Memory.new(string)
  end

  def self.new(slice : Bytes)
    new IO::Memory.new(slice)
  end

  def initialize(io : IO)
    @io = io
    @token = Token.new
    @byte_number = 0
    @current_byte = 0_u8
    @eof = false
  end

  def prefetch_token
    return @token unless @token.used
    next_byte

    return @token if @eof

    @token.used = false

    case current_byte
    when 0xC0
      set_type_and_size(:nil, 0)
    when 0xC2
      set_type_and_size(:false, 0)
    when 0xC3
      set_type_and_size(:true, 0)
    when 0xA0..0xBF
      consume_string(current_byte - 0xA0)
    when 0xE0..0xFF
      @token.type = :INT
      @token.int_value = current_byte.to_i8
    when 0x00..0x7f
      @token.type = :UINT
      @token.uint_value = current_byte
    when 0x80..0x8f
      set_type_and_size(:HASH, current_byte - 0x80)
    when 0x90..0x9f
      set_type_and_size(:ARRAY, current_byte - 0x90)
    when 0xC4
      consume_binary(next_byte)
    when 0xC5
      consume_binary(read UInt16)
    when 0xC6
      consume_binary(read UInt32)
    when 0xCA
      consume_float(read Float32)
    when 0xCB
      consume_float(read Float64)
    when 0xCC
      consume_uint(read UInt8)
    when 0xCD
      consume_uint(read UInt16)
    when 0xCE
      consume_uint(read UInt32)
    when 0xCF
      consume_uint(read UInt64)
    when 0xD0
      consume_int(read Int8)
    when 0xD1
      consume_int(read Int16)
    when 0xD2
      consume_int(read Int32)
    when 0xD3
      consume_int(read Int64)
    when 0xD9
      consume_string(read UInt8)
    when 0xDA
      consume_string(read UInt16)
    when 0xDB
      consume_string(read UInt32)
    when 0xDC
      set_type_and_size(:ARRAY, read UInt16)
    when 0xDD
      set_type_and_size(:ARRAY, read UInt32)
    when 0xDE
      set_type_and_size(:HASH, read UInt16)
    when 0xDF
      set_type_and_size(:HASH, read UInt32)
    else
      unexpected_byte!
    end

    @token
  end

  def next_token
    token = prefetch_token
    token.used = true
    token
  end

  private def next_byte
    @byte_number += 1
    byte = @io.read_byte

    unless byte
      @eof = true
      @token.type = :EOF
    end

    @token.byte_number = @byte_number

    @current_byte = byte || 0.to_u8
  end

  private def set_type_and_size(type, size)
    @token.type = type
    @token.size = size
  end

  private def consume_uint(value)
    @token.type = :UINT
    @token.uint_value = value
  end

  private def consume_int(value)
    @token.type = :INT
    @token.int_value = value
  end

  private def consume_float(value)
    @token.type = :FLOAT
    @token.float_value = value
  end

  private def consume_binary(size)
    size = size.to_u32
    bytes = Bytes.new(size)
    @io.read_fully(bytes)
    @token.type = :BINARY
    @token.binary_value = bytes
    @byte_number += size
  end

  private def consume_string(size)
    size = size.to_u32
    @token.type = :STRING
    @token.string_value = String.new(size) do |buffer|
      @io.read_fully(Slice.new(buffer, size))
      {size, 0}
    end
    @byte_number += size
  end

  private def read(type : T.class) forall T
    @byte_number += sizeof(T)
    @io.read_bytes(T, IO::ByteFormat::BigEndian)
  end

  private def unexpected_byte!(byte = current_byte)
    raise UnpackException.new("Unexpected byte '#{byte}'", @byte_number)
  end
end
