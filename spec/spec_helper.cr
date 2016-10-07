require "spec"
require "../src/message_pack"

include MessagePack

def as_slice(arr : Array(UInt8))
  Bytes.new(arr.to_unsafe, arr.size)
end

def it_packs_method(type, bytes)
  packer = MessagePack::Packer.new
  result = packer.write(type)
  result.bytes.should eq(bytes)
end

macro it_packs(type, bytes, file = __FILE__, line = __LINE__)
  it "serializes #{{{type.stringify}}} to #{{{bytes}}}", {{file}}, {{line}} do
    it_packs_method(({{type}}), {{bytes}})
  end
end
