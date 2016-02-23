def Object.from_msgpack(string_or_io)
  parser = MessagePack::PullParser.new(string_or_io)
  new parser
end

def Array.from_msgpack(string_or_io)
  parser = MessagePack::PullParser.new(string_or_io)
  new(parser) do |element|
    yield element
  end
end

def Nil.new(pull : MessagePack::PullParser)
  pull.read_nil
end

def Bool.new(pull : MessagePack::PullParser)
  pull.read_bool
end

def Int32.new(pull : MessagePack::PullParser)
  case pull.kind
  when :UINT
    pull.read_uint.to_i
  else
    pull.read_int.to_i
  end
end

def Int64.new(pull : MessagePack::PullParser)
  case pull.kind
  when :UINT
    pull.read_uint.to_i64
  else
    pull.read_int.to_i64
  end
end

def UInt32.new(pull : MessagePack::PullParser)
  case pull.kind
  when :INT
    pull.read_int.to_u32
  else
    pull.read_uint.to_u32
  end
end

def UInt64.new(pull : MessagePack::PullParser)
  case pull.kind
  when :INT
    pull.read_int.to_u64
  else
    pull.read_uint.to_u64
  end
end

def Float32.new(pull : MessagePack::PullParser)
  case pull.kind
  when :INT
    pull.read_int.to_f32
  when :UINT
    pull.read_uint.to_f32
  else
    pull.read_float.to_f32
  end
end

def Float64.new(pull : MessagePack::PullParser)
  case pull.kind
  when :INT
    pull.read_int.to_f
  when :UINT
    pull.read_uint.to_f
  else
    pull.read_float.to_f
  end
end

def String.new(pull : MessagePack::PullParser)
  pull.read_string
end

def Array.new(pull : MessagePack::PullParser)
  ary = new(pull.token_size.to_i32)
  new(pull) do |element|
    ary << element
  end
  ary
end

def Array.new(pull : MessagePack::PullParser)
  pull.read_array do
    yield T.new(pull)
  end
end

def Set.new(pull : MessagePack::PullParser)
  set = new
  pull.read_array do
    set << T.new(pull)
  end
  set
end

def Hash.new(pull : MessagePack::PullParser)
  hash = new(initial_capacity: pull.token_size.to_i32)
  pull.read_hash(false) do
    k = K.new(pull)
    if pull.kind == :nil
      pull.skip_value
    else
      hash[k] = V.new(pull)
    end
  end
  hash
end

def Tuple.new(pull : MessagePack::PullParser)
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
  def from_msgpack(pull : MessagePack::PullParser)
    string = pull.read_string
    parse(string)
  end
end

struct Time
  def self.from_msgpack(formatter : Time::Format, string_or_io)
    pull = MessagePack::PullParser.new(string_or_io)
    from_msgpack formatter, pull
  end

  def self.from_msgpack(formatter : Time::Format, pull : MessagePack::PullParser)
    formatter.parse(pull.read_string)
  end
end
