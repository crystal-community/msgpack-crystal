require "../src/message_pack"

file = File.open("packed.bin", "w+")

packer = MessagePack::Packer.new(file)
packer.write(1)
packer.write("a")
packer.write(true)
packer.write([1, "a", true])
packer.write({"a" => 1})
packer.write(Hash(MessagePack::Type, MessagePack::Type){"a" => 1, "b" => Array(MessagePack::Type){"a", "b", "c"}})

file.close

file = File.open("packed.bin", "r")
unpacker = MessagePack::Unpacker.new(file)

puts unpacker.read_int    # 1
puts unpacker.read_string # "a"
puts unpacker.read_bool   # true
puts unpacker.read_array  # [1, "a", true]
puts unpacker.read_hash   # {"a" => 1}
puts unpacker.read_hash   # {"a" => 128, "b" => ["a", "b", "c"]}
