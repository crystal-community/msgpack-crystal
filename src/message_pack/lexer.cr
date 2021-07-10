class MessagePack::Lexer
  @token : Token::T

  def initialize(@io : IO)
    @byte_number = 0
    @current_byte_number = 0
    @token = Token::NullT.new(0)
    @token_finished = true
  end

  @[AlwaysInline]
  def current_token : Token::T
    if @token_finished
      @token_finished = false
      @token = next_token
    else
      @token
    end
  end

  @[AlwaysInline]
  def finish_token!
    @token_finished = true
  end

  @[AlwaysInline]
  def read_token : Token::T
    if @token_finished
      @token = next_token
    else
      finish_token!
    end
    @token
  end

  private def next_token
    @current_byte_number = @byte_number
    current_byte = next_byte

    case current_byte
    when 0xC0
      Token::NullT.new(@current_byte_number)
    when 0xC2
      Token::BoolT.new(@current_byte_number, false)
    when 0xC3
      Token::BoolT.new(@current_byte_number, true)
    when 0xA0..0xBF
      consume_string(current_byte - 0xA0)
    when 0xE0..0xFF
      consume_int(current_byte.to_i8!)
    when 0x00..0x7F
      consume_int(current_byte)
    when 0x80..0x8F
      set_hash(current_byte - 0x80)
    when 0x90..0x9F
      set_array(current_byte - 0x90)
    when 0xC4
      consume_binary(read(UInt8))
    when 0xC5
      consume_binary(read(UInt16))
    when 0xC6
      consume_binary(read(UInt32))
    when 0xC7
      consume_ext(read(UInt8))
    when 0xC8
      consume_ext(read(UInt16))
    when 0xC9
      consume_ext(read(UInt32))
    when 0xCA
      consume_float(read Float32)
    when 0xCB
      consume_float(read Float64)
    when 0xCC
      consume_int(read(UInt8))
    when 0xCD
      consume_int(read(UInt16))
    when 0xCE
      consume_int(read(UInt32))
    when 0xCF
      consume_int(read(UInt64))
    when 0xD0
      consume_int(read(Int8))
    when 0xD1
      consume_int(read(Int16))
    when 0xD2
      consume_int(read(Int32))
    when 0xD3
      consume_int(read(Int64))
    when 0xD4..0xD8
      size = 1 << (current_byte - 0xD4) # 1, 2, 4, 8, 16
      consume_ext(size)
    when 0xD9
      consume_string(read UInt8)
    when 0xDA
      consume_string(read UInt16)
    when 0xDB
      consume_string(read UInt32)
    when 0xDC
      set_array(read UInt16)
    when 0xDD
      set_array(read UInt32)
    when 0xDE
      set_hash(read UInt16)
    when 0xDF
      set_hash(read UInt32)
    else
      # 0xC1 only
      raise UnexpectedByteError.new("Unexpected byte '#{current_byte}'", @current_byte_number)
    end
  end

  private def next_byte : UInt8
    byte = @io.read_byte
    @byte_number += 1
    raise EofError.new(@byte_number) unless byte
    byte
  end

  private def set_array(size)
    Token::ArrayT.new(@current_byte_number, size.to_u32)
  end

  private def set_hash(size)
    Token::HashT.new(@current_byte_number, size.to_u32)
  end

  private def consume_int(value)
    Token::IntT.new(@current_byte_number, value)
  end

  private def consume_float(value)
    Token::FloatT.new(@current_byte_number, value.to_f64)
  end

  private def consume_ext(size)
    type_id = read(Int8)
    size = size.to_u32
    bytes = Bytes.new(size)
    @io.read_fully(bytes.to_slice)
    @byte_number += size
    Token::ExtT.new(@current_byte_number, type_id, size, bytes)
  end

  private def consume_string(size)
    size = size.to_u32
    string_value = String.new(size) do |buffer|
      @io.read_fully(Slice.new(buffer, size))
      {size, 0}
    end
    @byte_number += size
    Token::StringT.new(@current_byte_number, string_value)
  end

  private def consume_binary(size)
    size = size.to_u32
    bytes = io_read_fully(size)
    @byte_number += size
    Token::BytesT.new(@current_byte_number, bytes)
  end

  private def read(type : T.class) forall T
    @byte_number += sizeof(T)
    @io.read_bytes(T, IO::ByteFormat::BigEndian)
  end

  protected def io_read_fully(size) : Bytes
    bytes = Bytes.new(size)
    @io.read_fully(bytes)
    bytes
  end

  class ZeroCopy < MessagePack::Lexer
    protected def io_read_fully(size) : Bytes
      io = @io.as IO::Memory
      bytes = io.to_slice[io.pos, size]
      io.pos += size
      bytes
    end
  end
end
