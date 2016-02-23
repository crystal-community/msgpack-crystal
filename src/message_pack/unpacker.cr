require "./lexer"

class MessagePack::Unpacker
  def initialize(string_or_io)
    @lexer = MessagePack::Lexer.new(string_or_io)
  end

  def self.new(array : Array(UInt8))
    slice = Slice(UInt8).new(array.to_unsafe, array.size)
    new(slice)
  end

  def read
    read_value
  end

  def read_nil
    next_token
    check :nil
    nil
  end

  def read_nil_or
    next_token
    if token.type == :nil
      nil
    else
      yield
    end
  end

  def read_bool
    next_token
    case token.type
    when :true
      true
    when :false
      false
    else
      unexpected_token
    end
  end

  def read_numeric
    next_token
    case token.type
      when :INT
        token.int_value
      when :UINT
        token.uint_value
      when :FLOAT
        token.float_value
      else
        unexpected_token
      end
  end

  {% for type in %w(int uint float string) %}
    def read_{{type.id}}                          # def read_int
      next_token
      check :{{type.id.upcase}}                   #   check :INT
      token.{{type.id}}_value                     #   token.int_value
    end                                           # end
  {% end %}

  def read_array_size
    next_token
    check :ARRAY
    token.size.to_i32
  end

  def read_array(fetch_next_token = true)
    next_token if fetch_next_token
    check :ARRAY
    Array(Type).new(token.size.to_i32) do
      read_value
    end
  end

  def read_array(fetch_next_token = true)
    next_token if fetch_next_token
    check :ARRAY
    token.size.times do
      yield
    end
  end

  def read_hash_size
    next_token
    check :HASH
    token.size.to_i32
  end

  def read_hash(read_key = true, fetch_next_token = true)
    next_token if fetch_next_token
    check :HASH
    token.size.times do
      if read_key
        key = read_value
        yield key
      else
        yield
      end
    end
  end

  def read_hash(fetch_next_token = true)
    next_token if fetch_next_token
    check :HASH
    hash = Hash(Type, Type).new(initial_capacity: token.size.to_i32)
    token.size.times do
      key = read_value
      value = read_value
      hash[key] = value
    end
    hash
  end

  def read_value
    next_token

    case token.type
    when :INT
      token.int_value
    when :UINT
      token.uint_value
    when :FLOAT
      token.float_value
    when :STRING
      token.string_value
    when :nil
      nil
    when :true
      true
    when :false
      false
    when :ARRAY
      read_array(false)
    when :HASH
      read_hash(false)
    else
      unexpected_token(token.type)
    end
  end

  def skip_value
    next_token
    case token.type
    when :INT, :UINT, :FLOAT, :STRING, :nil, :true, :false
      # Do nothing
    when :ARRAY
      token.size.times { skip_value }
    when :HASH
      token.size.times { skip_value; skip_value }
    else
      unexpected_token(token.type)
    end
  end

  private delegate token, @lexer
  private delegate next_token, @lexer

  private def check(token_type)
    unexpected_token(token_type) unless token.type == token_type
  end

  private def unexpected_token(token_type = nil)
    message = "unexpected token '#{token}'"
    message += " expected #{token_type}" if token_type
    raise UnpackException.new(message, token.byte_number)
  end
end
