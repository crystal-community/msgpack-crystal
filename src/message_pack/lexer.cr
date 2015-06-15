# :nodoc:
class MessagePack::Lexer
  getter token
  getter current_byte

  def initialize(io : IO)
    @io           = io
    @token        = Token.new
    @byte_number  = 0
    @current_byte = 0
    @eof          = false
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
      consume_string(read_uint(16))
    when 0xC6
      consume_string(read_uint(32))
    when 0xCA
      consume_float(32)
    when 0xCB
      consume_float(64)
    when 0xCC 
      consume_uint(8)
    when 0xCD
      consume_uint(16)
    when 0xCE
      consume_uint(32)
    when 0xCF
      consume_uint(64)
    when 0xD0
      consume_int(8)
    when 0xD1
      consume_int(16)
    when 0xD2
      consume_int(32)
    when 0xD3
      consume_int(64)
    when 0xD9
      consume_string(read_uint(8))
    when 0xDA
      consume_string(read_uint(16))
    when 0xDB
      consume_string(read_uint(32))
    when 0xDC
      next_byte(:ARRAY, read_uint(16))
    when 0xDD
      next_byte(:ARRAY, read_uint(32))
    when 0xDE
      next_byte(:HASH, read_uint(16))
    when 0xDF
      next_byte(:HASH, read_uint(32))
    when 
      unexpected_byte
    end

    @token
  end

  private def next_byte
    @byte_number += 1
    byte = @io.read_byte 

    unless byte
      @eof = true
    end

    @current_byte = (byte || 0.to_u8) as UInt8
  end

  private def next_byte(type, size)
    @token.type = type
    @token.size = size
    next_byte
  end 

  private def consume_uint(size)
    @token.type = :UINT
    @token.uint_value = read_uint(size)
    next_byte
  end

  private def consume_int(size)
    @token.type = :INT
    @token.int_value = read_int(size)
    next_byte
  end

  private def consume_float(size)
    @token.type = :FLOAT
    @token.float_value = read_float(size)
    next_byte
  end

  private def read_uint(size)
    @byte_number += size / 8
    case size
    when 8
      next_byte
    when 16
      b1, b2 = [next_byte, next_byte]
      tuple16 = {b2, b1}
      (pointerof(tuple16) as UInt16*).value
    when 32
      b1, b2, b3, b4 = [next_byte, next_byte, next_byte, next_byte]
      tuple32 = {b4 , b3, b2, b1}
      (pointerof(tuple32) as UInt32*).value
    when 64
      b1, b2, b3, b4, b5, b6, b7, b8 = [next_byte, next_byte, next_byte, next_byte, next_byte, next_byte, next_byte, next_byte]
      tuple64 = {b8, b7, b6, b5, b4 , b3, b2, b1}
      (pointerof(tuple64) as UInt64*).value
    else
      raise "Invalid UInt size expected 2, 4 or 8 got #{size}"
    end
  end

  private def read_int(size)
    @byte_number += size / 8
    case size
    when 8
      next_byte.to_i8
    when 16
      b1, b2 = [next_byte, next_byte]
      tuple16 = {b2, b1}
      (pointerof(tuple16) as Int16*).value
    when 32
      b1, b2, b3, b4 = [next_byte, next_byte, next_byte, next_byte]
      tuple32 = {b4 , b3, b2, b1}
      (pointerof(tuple32) as Int32*).value
    when 64
      b1, b2, b3, b4, b5, b6, b7, b8 = [next_byte, next_byte, next_byte, next_byte, next_byte, next_byte, next_byte, next_byte]
      tuple64 = {b8, b7, b6, b5, b4 , b3, b2, b1}
      (pointerof(tuple64) as Int64*).value
    else
      raise "Invalid Int size expected 16, 32 or 64 got #{size}"
    end
  end

  private def read_float(size)
    @byte_number += size / 8
    case size
    when 32
      b1, b2, b3, b4 = [next_byte, next_byte, next_byte, next_byte]
      tuple32 = {b4 , b3, b2, b1}
      (pointerof(tuple32) as Float32*).value
    when 64
      b1, b2, b3, b4, b5, b6, b7, b8 = [next_byte, next_byte, next_byte, next_byte, next_byte, next_byte, next_byte, next_byte]
      tuple64 = {b8, b7, b6, b5, b4 , b3, b2, b1}
      (pointerof(tuple64) as Float64*).value
    else
      raise "Invalid UInt size expected 32 or 64 got #{size}"
    end
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

  private def unexpected_byte(byte = current_byte)
    raise "unexpected byte '#{byte}'"
  end

  private def raise(msg)
    ::raise ParseException.new(msg, @byte_number)
  end
end
