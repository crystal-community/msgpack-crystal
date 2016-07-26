require "msgpack" # gem install msgpack

$summary_packed = 0

def test_pack(name, count, data)
  t = Time.now
  print name
  res = 0
  count.times do |i|
    res += data.to_msgpack.bytesize
  end
  puts " = #{res}, #{Time.now - t}"
  $summary_packed += res
end

def bytes(size)
  "\0" * size
end

def byte(value)
  [value].pack("C")
end

t = Time.now

test_pack("small string", 1000000, "a" * 200)
test_pack("small binary", 1000000, bytes(200))
test_pack("big string", 10000, "a" * 200000)
test_pack("big binary", 10000, bytes(200000))
test_pack("hash string string", 10000, (0..1000).reduce({}) { |h, i| h["key#{i}"] = "value#{i}"; h })
test_pack("hash string binary", 10000, (0..1000).reduce({}) { |h, i| h["key#{i}"] = byte(i); h })
test_pack("hash string float64", 10000, (0..1000).reduce({}) { |h, i| h["key#{i}"] = i / 10.0; h })
test_pack("array of strings", 10000, Array.new(1000) { |i| "data#{i}" })
test_pack("array of binaries", 10000, Array.new(1000) { |i| byte(i) })
test_pack("array of floats", 20000, Array.new(3000) { |i| i / 10.0 })

ints = [1, -1, 0x21, -0x21, 128, -128, -0x8000, 0x8000, 0xFFFF, -0xFFFF, -0x80000000, 0x80000000, -9223372036854775808, 9223372036854775807, 4294967295, -4294967295]
test_pack("array of mix int sizes", 2000, Array.new(30000) { |i| ints[i % ints.size] })

data = [Array.new(30) { |i| i }, Array.new(30) { |i| i.to_s }, (0..30).reduce({}) { |h, i| h[i] = i.to_s; h }, 1, "1"]
test_pack("array of mix of data", 200, Array.new(10000) { |i| data[i % data.size] })

puts "Summary packed size: #{$summary_packed} bytes"
puts "Summary time: #{Time.now - t}"
