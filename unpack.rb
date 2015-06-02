require 'msgpack'

bytes = STDIN.read
start = Time.now
size = MessagePack.unpack(bytes).length

puts "Parse #{size} items in #{(Time.now - start) * 1000} ms"