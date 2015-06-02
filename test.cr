require "./src/msgpack"

bytes = STDIN.read.bytes

slice = Slice(UInt8).new(bytes.size.to_i32) { |i| bytes[i] }

start = Time.now
size = (Msgpack.unpack(slice) as Array(Msgpack::MsgpackTypes)).length

puts "Parse #{size} items in #{(Time.now - start).milliseconds} ms"