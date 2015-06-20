require "msgpack"
require "stringio"

io = StringIO.new(File.read("/tmp/msgpack"))
start = Time.now
MessagePack.unpack(io)

puts "Took: #{(Time.now - start)*1000}ms"
