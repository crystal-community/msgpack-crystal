require "base64"

def Object.from_msgpack(string_or_io)
  parser = MessagePack::Unpacker.new(string_or_io)
  new parser
end

def Object.from_msgpack64(string_or_io)
  from_msgpack(Base64.decode(string_or_io))
end

def Array.from_msgpack(string_or_io)
  parser = MessagePack::Unpacker.new(string_or_io)
  new(parser) do |element|
    yield element
  end
end

def Nil.new(pull : MessagePack::Unpacker)
  pull.read_nil
end

def Bool.new(pull : MessagePack::Unpacker)
  pull.read_bool
end

{% for size in [8, 16, 32, 64] %}
  def Int{{size.id}}.new(pull : MessagePack::Unpacker)
    case pull.prefetch_token.type
    when :UINT
      pull.read_uint.to_i{{size.id}}
    else
      pull.read_int.to_i{{size.id}}
    end
  end

  def UInt{{size.id}}.new(pull : MessagePack::Unpacker)
    case pull.prefetch_token.type
    when :INT
      pull.read_int.to_u{{size.id}}
    else
      pull.read_uint.to_u{{size.id}}
    end
  end
{% end %}

def Float32.new(pull : MessagePack::Unpacker)
  case pull.prefetch_token.type
  when :INT
    pull.read_int.to_f32
  when :UINT
    pull.read_uint.to_f32
  else
    pull.read_float.to_f32
  end
end

def Float64.new(pull : MessagePack::Unpacker)
  case pull.prefetch_token.type
  when :INT
    pull.read_int.to_f
  when :UINT
    pull.read_uint.to_f
  else
    pull.read_float.to_f
  end
end

def String.new(pull : MessagePack::Unpacker)
  pull.read_string
end

def Slice(UInt8).new(pull : MessagePack::Unpacker)
  pull.read_binary
end

def Array.new(pull : MessagePack::Unpacker)
  ary = new(pull.prefetch_token.size.to_i32)
  new(pull) do |element|
    ary << element
  end
  ary
end

def Array.new(pull : MessagePack::Unpacker)
  pull.read_array do
    yield T.new(pull)
  end
end

def Set.new(pull : MessagePack::Unpacker)
  set = new
  pull.read_array do
    set << T.new(pull)
  end
  set
end

def Hash.new(pull : MessagePack::Unpacker)
  hash = new(initial_capacity: pull.prefetch_token.size.to_i32)
  pull.read_hash(false) do
    k = K.new(pull)
    t = pull.prefetch_token
    if t.type == :nil
      pull.skip_value
    else
      hash[k] = V.new(pull)
    end
  end
  hash
end

def Enum.new(pull : MessagePack::Unpacker)
  type = pull.prefetch_token.type
  case type
  when :INT
    from_value(pull.read_int)
  when :UINT
    from_value(pull.read_uint)
  when :STRING
    parse(pull.read_string)
  else
    raise "expecting int, uint or string in MessagePack for #{self.class}, not #{type}"
  end
end

def Tuple.new(pull : MessagePack::Unpacker)
  {% if true %}
    pull.read_array_size
    value = Tuple.new(
      {% for i in 0...@type.size %}
        (self[{{i}}].new(pull)),
      {% end %}
    )
    value
 {% end %}
end

struct Time::Format
  def from_msgpack(pull : MessagePack::Unpacker)
    string = pull.read_string
    parse(string)
  end
end

struct Time
  def self.from_msgpack(formatter : Time::Format, string_or_io)
    pull = MessagePack::Unpacker.new(string_or_io)
    from_msgpack formatter, pull
  end

  def self.from_msgpack(formatter : Time::Format, pull : MessagePack::Unpacker)
    formatter.parse(pull.read_string)
  end
end
