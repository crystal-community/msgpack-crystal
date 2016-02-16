require "spec"
require "../src/message_pack"

include MessagePack

def as_slice(arr : Array(UInt8))
  Slice(UInt8).new(arr.to_unsafe, arr.size)
end
