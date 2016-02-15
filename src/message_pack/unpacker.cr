require "./lexer"

class MessagePack::Unpacker
  def initialize(string_or_io)
    @lexer = MessagePack::Lexer.new(string_or_io)
    next_token
  end

  def has_next
    token.type != :EOF
  end

  def read
    value = read_value
    check :EOF
    value
  end

  def read_int
    check :INT
    token.int_value.tap { next_token }
  end

  def read_uint
    check :UINT
    token.uint_value.tap { next_token }
  end

  def read_float
    check :FLOAT
    token.float_value.tap { next_token }
  end

  def read_string
    check :STRING
    token.string_value.tap { next_token }
  end

  def read_nil
    check :nil
    nil.tap { next_token }
  end

  def read_bool
    case token.type
    when :true
      next_token
      true
    when :false
      next_token
      false
    else
      unexpected_token
    end
  end

  def read_array
    size = token.size
    next_token

    size.times do
      yield
    end
  end

  def read_array
    size = token.size
    next_token
    Array(Type).new(size.to_i32) do
      read_value
    end
  end

  def read_hash(read_key = true)
    size = token.size
    next_token

    size.times do
      if read_key
        key = read_value
        yield key
      else
        yield
      end
    end
  end

  def read_hash
    hash = Hash(Type, Type).new(initial_capacity: token.size.to_i32)
    read_hash do |key|
      hash[key] = read_value
    end
    hash
  end

  def read_value
    case token.type
    when :INT
      value_and_next_token token.int_value
    when :UINT
      value_and_next_token token.uint_value
    when :FLOAT
      value_and_next_token token.float_value
    when :STRING
      value_and_next_token token.string_value
    when :nil
      value_and_next_token nil
    when :true
      value_and_next_token true
    when :false
      value_and_next_token false
    when :ARRAY
      read_array
    when :HASH
      read_hash
    else
      unexpected_token
    end
  end

  private delegate token, @lexer
  private delegate next_token, @lexer

  private def value_and_next_token(value)
    next_token
    value
  end

  private def check(token_type)
    unexpected_token unless token.type == token_type
  end

  private def unexpected_token
    raise UnpackException.new("unexpected token '#{token}'", token.byte_number)
  end
end
