require "spec"
require "../src/message_pack"

def as_slice(arr : Array(UInt8))
  Bytes.new(arr.to_unsafe, arr.size)
end

def it_packs_method(value, bytes)
  packer = MessagePack::Packer.new
  result = packer.write(value)
  result.bytes.should eq(bytes)
end

def it_unpacks_method(value, bytes)
  packer = MessagePack::IOUnpacker.new(bytes)
  result = packer.read
  result.should eq(value)
end

macro it_packs(value, bytes, unpack_value = nil, file = __FILE__, line = __LINE__)
  it "serializes #{{{value.stringify}}} to #{{{bytes}}}", {{file}}, {{line}} do
    it_packs_method(({{value}}), {{bytes}})
    it_unpacks_method(({{unpack_value}} || {{value}}), {{bytes}})
  end
end

class ExtClass
  getter a, b

  # Some number of this type
  TYPE_ID = 25_i8

  def initialize(@a : Int32, @b : String)
  end

  def self.new(pull : MessagePack::Unpacker)
    pull.read_ext(TYPE_ID) do |size, io|
      a = io.read_bytes(Int32, IO::ByteFormat::BigEndian)
      size -= 4
      b = String.new(size) do |buffer|
        io.read_fully(Slice.new(buffer, size))
        {size, 0}
      end

      self.new(a, b)
    end
  end

  def to_msgpack(packer : MessagePack::Packer)
    packer.write_ext(TYPE_ID) do |io|
      io.write_bytes(@a, IO::ByteFormat::BigEndian)
      io.write(@b.to_slice)
    end
  end
end
