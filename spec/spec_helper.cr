require "spec"
require "../src/message_pack"

include MessagePack

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
