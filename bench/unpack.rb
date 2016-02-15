require "msgpack"
# gem install msgpack

def test_unpack(name, count, data)
  packed = data.to_msgpack
  t = Time.now
  print name
  count.times do |i|
    MessagePack.unpack(packed)
  end
  puts " = #{Time.now - t}"
end

t = Time.now

test_unpack("small string", 1000000, "a" * 200)
test_unpack("big string", 10000, "a" * 200000)
test_unpack("hash string string", 10000, (0..1000).reduce({}) { |h, i| h["key#{i}"] = "value#{i}"; h })
test_unpack("hash string float64", 10000, (0..1000).reduce({}) { |h, i| h["key#{i}"] = i / 10.0; h })
test_unpack("array of strings", 10000, Array.new(1000) { |i| "data#{i}" })
test_unpack("array of floats", 20000, Array.new(3000) { |i| i / 10.0 })

puts "Summary time: #{Time.now - t}"
