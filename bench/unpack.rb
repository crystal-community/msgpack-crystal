require "msgpack"

$summary_unpacked = 0

def test_unpack(name, count, data)
  slice = data.to_msgpack
  t = Time.now
  print name
  res = 0
  count.times do |i|
    obj = MessagePack.unpack(slice)
    res += obj.size
  end
  $summary_unpacked += res
  puts " = #{res}, #{Time.now - t}"
end

def bytes(size)
  "\0" * size
end

def byte(value)
  [value].pack("C")
end

t = Time.now

test_unpack("small string", 1000000, "a" * 200)
test_unpack("small binary", 1000000, bytes(200))
test_unpack("big string", 10000, "a" * 200000)
test_unpack("big binary", 10000, bytes(200000))
test_unpack("hash string string", 10000, (0..1000).reduce({}) { |h, i| h["key#{i}"] = "value#{i}"; h })
test_unpack("hash string binary", 10000, (0..1000).reduce({}) { |h, i| h["key#{i}"] = byte(i); h })
test_unpack("hash string float64", 10000, (0..1000).reduce({}) { |h, i| h["key#{i}"] = i / 10.0; h })
test_unpack("array of strings", 10000, Array.new(1000) { |i| "data#{i}" })
test_unpack("array of binaries", 10000, Array.new(1000) { |i| byte(i) })
test_unpack("array of floats", 20000, Array.new(3000) { |i| i / 10.0 })

ints = [1, -1, 0x21, -0x21, 128, -128, -0x8000, 0x8000, 0xFFFF, -0xFFFF, -0x80000000, 0x80000000, -9223372036854775808, 9223372036854775807, 4294967295, -4294967295]
test_unpack("array of mix int sizes", 2000, Array.new(30000) { |i| ints[i % ints.size] })

data = [Array.new(30) { |i| i }, Array.new(30) { |i| i.to_s }, (0..30).reduce({}) { |h, i| h[i] = i.to_s; h }, 1, "1"]
test_unpack("array of mix of data", 200, Array.new(10000) { |i| data[i % data.size] })

puts "Summary unpacked size: #{$summary_unpacked}"
puts "Summary time: #{Time.now - t}"
