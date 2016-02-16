require "msgpack"

def test_unpack(name, count, data)
  slice = data.to_msgpack
  t = Time.now
  print name
  res = 0
  count.times do |i|
    obj = MessagePack.unpack(slice)
    res += obj.size
  end
  puts " = #{res}, #{Time.now - t}"
end

t = Time.now

test_unpack("small string", 1000000, "a" * 200)
test_unpack("big string", 10000, "a" * 200000)
test_unpack("hash string string", 10000, (0..1000).reduce({}) { |h, i| h["key#{i}"] = "value#{i}"; h })
test_unpack("hash string float64", 10000, (0..1000).reduce({}) { |h, i| h["key#{i}"] = i / 10.0; h })
test_unpack("array of strings", 10000, Array.new(1000) { |i| "data#{i}" })
test_unpack("array of floats", 20000, Array.new(3000) { |i| i / 10.0 })
test_unpack("array of mix int sizes", 20000, Array.new(3000) { |i| [0xFF, 0xFFFF, 0xFFFFFFFF][i % 3] })

puts "Summary time: #{Time.now - t}"
