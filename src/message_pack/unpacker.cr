require "./lexer"

abstract class MessagePack::Unpacker
  abstract def token : Token
  abstract def next_token : Token
  abstract def prefetch_token : Token

  def read
    read_value
  end

  def read_nil
    next_token
    check Token::Type::Null
    nil
  end

  def read_nil_or
    token = prefetch_token
    if token.type.null?
      token.used = true
      nil
    else
      yield
    end
  end

  def read_bool
    next_token
    case token.type
    when .true?
      true
    when .false?
      false
    else
      unexpected_token
    end
  end

  def read_numeric
    next_token
    case token.type
    when .int?
      token.int_value
    when .uint?
      token.uint_value
    when .float?
      token.float_value
    else
      unexpected_token
    end
  end

  {% for type in %w(Int Uint Float String Binary) %}
    def read_{{type.id.downcase}}                 # def read_int
      next_token                                  #   next_token
      check Token::Type::{{type.id}}              #   check Token::Type::Int
      token.{{type.id.downcase}}_value            #   token.int_value
    end                                           # end
  {% end %}

  def read_array_size
    next_token
    check Token::Type::Array
    token.size.to_i32
  end

  def read_array(fetch_next_token = true)
    next_token if fetch_next_token
    check Token::Type::Array
    Array(Type).new(token.size.to_i32) do
      read_value
    end
  end

  def read_array(fetch_next_token = true)
    next_token if fetch_next_token
    check Token::Type::Array
    token.size.times do
      yield
    end
  end

  def read_hash_size
    next_token
    check Token::Type::Hash
    token.size.to_i32
  end

  def read_hash(read_key = true, fetch_next_token = true)
    next_token if fetch_next_token
    check Token::Type::Hash
    token.size.times do
      if read_key
        key = read_value
        yield key
      else
        yield nil
      end
    end
  end

  def read_hash(fetch_next_token = true)
    next_token if fetch_next_token
    check Token::Type::Hash
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
    when .int?
      token.int_value
    when .uint?
      token.uint_value
    when .float?
      token.float_value
    when .string?
      token.string_value
    when .binary?
      token.binary_value
    when .null?
      nil
    when .true?
      true
    when .false?
      false
    when .array?
      read_array(false)
    when .hash?
      read_hash(false)
    else
      unexpected_token(token.type)
    end
  end

  def read_value_tokens
    res = [] of Token
    _read_value_as_array_of_tokens(res)
    res
  end

  private def _read_value_as_array_of_tokens(res)
    next_token
    res << token.dup

    case token.type
    when .array?
      token.size.times { _read_value_as_array_of_tokens(res) }
    when .hash?
      token.size.times do
        _read_value_as_array_of_tokens(res)
        _read_value_as_array_of_tokens(res)
      end
    end

    true
  end

  def skip_value
    next_token
    case token.type
    when .int?, .uint?, .float?, .string?, .binary?, .null?, .true?, .false?
      # Do nothing
    when .array?
      token.size.times { skip_value }
    when .hash?
      token.size.times { skip_value; skip_value }
    else
      unexpected_token(token.type)
    end
  end

  def read?(klass : Bool.class)
    read_bool if token.type.false? || token.type.true?
  end

  def read?(klass : Int8.class)
    read_int.to_i8 if token.type.int?
    read_uint.to_i8 if token.type.uint?
  end

  def read?(klass : Int16.class)
    read_int.to_i16 if token.type.int?
    read_uint.to_i16 if token.type.uint?
  end

  def read?(klass : Int32.class)
    read_int.to_i32 if token.type.int?
    read_uint.to_i32 if token.type.uint?
  end

  def read?(klass : Int64.class)
    read_int.to_i64 if token.type.int?
    read_uint.to_i64 if token.type.uint?
  end

  def read?(klass : UInt8.class)
    read_int.to_u8 if token.type.int?
    read_uint.to_u8 if token.type.uint?
  end

  def read?(klass : UInt16.class)
    read_int.to_u16 if token.type.int?
    read_uint.to_u16 if token.type.uint?
  end

  def read?(klass : UInt32.class)
    read_int.to_u32 if token.type.int?
    read_uint.to_u32 if token.type.uint?
  end

  def read?(klass : UInt64.class)
    read_int.to_u64 if token.type.int?
    read_uint.to_u64 if token.type.uint?
  end

  def read?(klass : Float32.class)
    return read_int.to_f32 if token.type.int?
    return read_uint.to_f32 if token.type.uint?
    return read_float.to_f32 if token.type.float?
  end

  def read?(klass : Float64.class)
    return read_int.to_f64 if token.type.int?
    return read_uint.to_f64 if token.type.uint?
    return read_float.to_f64 if token.type.float?
  end

  def read?(klass : String.class)
    read_string if token.type.string?
  end

  private def check(token_type)
    unexpected_token(token_type) unless token.type == token_type
  end

  private def unexpected_token(token_type = nil)
    message = "unexpected token '#{token}'"
    message += " expected #{token_type}" if token_type
    raise UnpackException.new(message, token.byte_number)
  end
end

require "./unpacker/*"
