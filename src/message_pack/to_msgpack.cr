require "base64"

class Object
  def to_msgpack
    packer = MessagePack::Packer.new
    to_msgpack(packer)
    packer.to_slice
  end

  def to_msgpack64
    Base64.encode(to_msgpack)
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

struct Time::Format
  def to_msgpack(value : Time, packer : MessagePack::Packer)
    format(value).to_msgpack(packer)
  end
end

struct Time
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
