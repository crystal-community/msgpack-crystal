class Object
  def to_msgpack
    packer = MessagePack::Packer.new
    to_msgpack(packer)
    packer.to_slice
  end

  def to_msgpack(io : IO)
    packer = MessagePack::Packer.new(io)
    to_msgpack(packer)
    self
  end

  def to_msgpack(packer : MessagePack::Packer)
    packer.write(self)
  end
end

struct Set
  def to_msgpack(packer : MessagePack::Packer)
    packer.write_array_start(self.size)
    each { |elem| elem.to_msgpack(packer) }
  end
end

class Array
  def to_msgpack(packer : MessagePack::Packer)
    packer.write_array_start(self.size)
    each { |elem| elem.to_msgpack(packer) }
  end
end

class Hash
  def to_msgpack(packer : MessagePack::Packer)
    packer.write_hash_start(self.size)
    each do |key, value|
      key.to_msgpack(packer)
      value.to_msgpack(packer)
    end
  end
end

struct Tuple
  def to_msgpack(packer : MessagePack::Packer)
    packer.write_array_start(self.size)
    each { |elem| elem.to_msgpack(packer) }
  end
end

struct NamedTuple
  def to_msgpack(packer : MessagePack::Packer)
    packer.write_hash_start(self.size)
    {% for key in T.keys %}
      {{key.stringify}}.to_msgpack(packer)
      self[{{key.symbolize}}].to_msgpack(packer)
    {% end %}
  end
end

struct Time::Format
  def to_msgpack(value : Time, packer : MessagePack::Packer)
    format(value).to_msgpack(packer)
  end
end

struct Time
  # Emits a string formated according to [RFC 3339](https://tools.ietf.org/html/rfc3339)
  # ([ISO 8601](http://xml.coverpages.org/ISO-FDIS-8601.pdf) profile).
  #
  # The MsgPack format itself does not specify a time data type, this method just
  # assumes that a string holding a RFC 3339 time format will be interpreted as
  # a time value.
  #
  # See `#from_msgpack` for reference.
  def to_msgpack(packer : MessagePack::Packer)
    Time::Format::RFC_3339.format(self, fraction_digits: 0).to_msgpack(packer)
  end

  def to_msgpack(formatter : Time::Format, packer : MessagePack::Packer)
    formatter.format(self).to_msgpack(packer)
  end

  def to_msgpack(formatter : Time::Format)
    packer = MessagePack::Packer.new
    to_msgpack(formatter, packer)
    packer.to_slice
  end
end

struct Enum
  def to_msgpack(packer : MessagePack::Packer)
    value.to_msgpack(packer)
  end
end

struct MessagePack::Any
  def to_msgpack(packer : MessagePack::Packer)
    packer.write(@raw)
  end
end
