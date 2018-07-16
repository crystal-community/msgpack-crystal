require "../src/message_pack"

io = IO::Memory.new

1.to_msgpack(io)
"a".to_msgpack(io)
true.to_msgpack(io)
{1, "a", true}.to_msgpack(io)
{"a" => 1}.to_msgpack(io)
{"a" => 1, "b" => {"a", "b", "c"}}.to_msgpack(io)

io.flush
io.rewind

puts Int32.from_msgpack(io)                           # 1
puts String.from_msgpack(io)                          # "a"
puts Bool.from_msgpack(io)                            # true
puts Tuple(Int32, String, Bool).from_msgpack(io)      # {1, "a", true}
puts Hash(String, Int32).from_msgpack(io)             # {"a" => 1}
puts Hash(String, MessagePack::Type).from_msgpack(io) # {"a" => 128, "b" => ["a", "b", "c"]}
