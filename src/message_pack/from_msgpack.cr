def Object.from_msgpack(string_or_io, zero_copy = false)
  parser = MessagePack::IOUnpacker.new(string_or_io, zero_copy)
  new parser
end

def Hash.from_msgpack(string_or_io, default_value, zero_copy = false)
  parser = MessagePack::IOUnpacker.new(string_or_io, zero_copy)
  new(parser, default_value)
end

def Hash.from_msgpack(string_or_io, zero_copy = false, &block : (Hash(K, V), K -> V))
  parser = MessagePack::IOUnpacker.new(string_or_io, zero_copy)
  new(parser, block)
end

def Nil.new(pull : MessagePack::Unpacker)
  pull.read_nil
end

def Bool.new(pull : MessagePack::Unpacker)
  pull.read_bool
end

{% for size in [8, 16, 32, 64] %}
  def Int{{size.id}}.new(pull : MessagePack::Unpacker)
    pull.read_int.to_i{{size.id}}
  end

  def UInt{{size.id}}.new(pull : MessagePack::Unpacker)
    pull.read_int.to_u{{size.id}}
  end
{% end %}

def Float32.new(pull : MessagePack::Unpacker)
  pull.read_numeric.to_f32
end

def Float64.new(pull : MessagePack::Unpacker)
  pull.read_numeric.to_f
end

def String.new(pull : MessagePack::Unpacker)
  pull.read_string
end

def Slice.new(pull : MessagePack::Unpacker)
  pull.read_bytes.to_slice
end

def Array.new(pull : MessagePack::Unpacker)
  arr = new(pull.read_array_size)
  pull.consume_array { arr << T.new(pull) }
  arr
end

def Set.new(pull : MessagePack::Unpacker)
  set = new
  pull.consume_array { set << T.new(pull) }
  set
end

def Hash.new(pull : MessagePack::Unpacker, block : (Hash(K, V), K -> V)? = nil)
  hash = new(block, initial_capacity: pull.read_hash_size)
  pull.consume_hash do
    k = K.new(pull)
    pull.read_nil_or { hash[k] = V.new(pull) }
  end
  hash
end

def Hash.new(pull : MessagePack::Unpacker, default_value : V)
  hash = new(default_value: default_value, initial_capacity: pull.read_hash_size)
  pull.consume_hash do
    k = K.new(pull)
    pull.read_nil_or { hash[k] = V.new(pull) }
  end
  hash
end

def Enum.new(pull : MessagePack::Unpacker)
  case token = pull.current_token
  when MessagePack::Token::IntT
    pull.finish_token!
    from_value(token.value)
  when MessagePack::Token::StringT
    pull.finish_token!
    parse(token.value)
  else
    pull.unexpected_token(token, "IntT or StringT")
  end
end

def Union.new(pull : MessagePack::Unpacker)
  token = pull.current_token

  # Optimization: use fast path for primitive types
  {% begin %}
    # Here we store types that are not primitive types
    {% non_primitives = [] of Nil %}

    {% for type, index in T %}
      {% if type == Nil %}
        return pull.read_nil if token.is_a?(MessagePack::Token::NullT)
      {% elsif type == Bool %}
        return pull.read_bool if token.is_a?(MessagePack::Token::BoolT)
      {% elsif type == String %}
        return pull.read_string if token.is_a?(MessagePack::Token::StringT)
      {% elsif type == Int8 || type == Int16 || type == Int32 || type == Int64 ||
                 type == UInt8 || type == UInt16 || type == UInt32 || type == UInt64 %}
        return {{type}}.new(pull) if token.is_a?(MessagePack::Token::IntT)
      {% elsif type == Float32 || type == Float64 %}
        return {{type}}.new(pull) if token.is_a?(MessagePack::Token::FloatT)
        {% unless T.any? { |t| t < Int } %}
          return {{type}}.new(pull) if token.is_a?(MessagePack::Token::IntT)
        {% end %}
      {% else %}
        {% non_primitives << type %}
      {% end %}
    {% end %}

    # If after traversing all the types we are left with just one
    # non-primitive type, we can parse it directly (no need to use `read_raw`)
    {% if non_primitives.size == 1 %}
      return {{non_primitives[0]}}.new(pull)
    {% else %}
      node = pull.read_node
      {% for type in non_primitives %}
        unpacker = MessagePack::NodeUnpacker.new(node)
        begin
          return {{type}}.new(unpacker)
        rescue e : MessagePack::TypeCastError
          # ignore
        end
      {% end %}
    {% end %}
  {% end %}

  raise MessagePack::TypeCastError.new("Couldn't parse data as " + {{T.stringify}}, token.byte_number)
end

def Tuple.new(pull : MessagePack::Unpacker)
  {% begin %}
    size = pull.read_array_size
    token = pull.current_token

    unless {{ @type.size }} <= size
      raise MessagePack::TypeCastError.new("Expected array with size #{ {{ @type.size }} }, but got #{size}", token.byte_number)
    end
    pull.finish_token!

    value = Tuple.new(
      {% for i in 0...@type.size %}
        (self[{{i}}].new(pull)),
      {% end %}
    )

    (size - {{ @type.size }}).times { pull.skip_value }

    value
  {% end %}
end

def NamedTuple.new(pull : MessagePack::Unpacker)
  {% begin %}
    {% for key in T.keys %}
      %var{key.id} = nil
    {% end %}

    token = pull.current_token
    pull.consume_table do |key|
      case key
        {% for key, type in T %}
          when {{key.stringify}}
            %var{key.id} = {{type}}.new(pull)
        {% end %}
      else
        pull.skip_value
      end
    end

    {% for key, type in T %}
      if %var{key.id}.nil? && !::Union({{type}}).nilable?
        raise MessagePack::TypeCastError.new("Missing msgpack attribute: {{key}}", token.byte_number)
      end
    {% end %}

    {
      {% for key, type in T %}
        {{key}}: %var{key.id}.as({{type}}),
      {% end %}
    }
  {% end %}
end

struct Time::Format
  def from_msgpack(pull : MessagePack::Unpacker)
    string = pull.read_string
    parse(string, Time::Location::UTC)
  end
end

# Reads a string from MsgPack parser as a time formated according to [RFC 3339](https://tools.ietf.org/html/rfc3339)
# or other variations of [ISO 8601](http://xml.coverpages.org/ISO-FDIS-8601.pdf).
#
# The MsgPack format itself does not specify a time data type, this method just
# assumes that a string holding a ISO 8601 time format can be # interpreted as a
# time value.
#
# See `#to_msgpack` for reference.
def Time.new(pull : MessagePack::Unpacker)
  Time::Format::ISO_8601_DATE_TIME.parse(pull.read_string)
end

struct Time
  def self.from_msgpack(formatter : Time::Format, string_or_io)
    pull = MessagePack::IOUnpacker.new(string_or_io)
    from_msgpack formatter, pull
  end

  def self.from_msgpack(formatter : Time::Format, pull : MessagePack::Unpacker)
    formatter.parse(pull.read_string, Time::Location::UTC)
  end
end

def MessagePack::Type.new(pull : MessagePack::Unpacker)
  pull.read
end

def MessagePack::Any.new(pull : MessagePack::Unpacker)
  new(pull.read)
end
