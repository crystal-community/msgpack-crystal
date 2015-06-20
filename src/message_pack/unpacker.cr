require "./lexer"

class MessagePack::Unpacker
  def initialize(string_or_io)
    @lexer = MessagePack::Lexer.new(string_or_io)
    next_token
  end

  def read
    value = read_value
    check :EOF
    value
  end

  private def read_value
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

  private def read_array
    size = token.size
    next_token
    ary = [] of Type

    size.times do
      ary << read_value
    end

    ary
  end

  private def read_hash
    size = token.size
    next_token
    hash = {} of Type => Type

    size.times do
      key       = read_value
      hash[key] = read_value
    end

    hash
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
