require "../src/msgpack"

def test_unpack(name, count, klass, data)
  slice = data.to_msgpack
  t = Time.now
  print name
  res = 0
  count.times do |i|
    obj = klass.from_msgpack(slice)
    res += obj.size
  end
  puts " = #{res}, #{Time.now - t}"
end

def bytes(size : Int32) : Slice(UInt8)
  Slice(UInt8).new(size) { |i| i.to_u8 }
end

def byte(value : Int32) : Slice(UInt8)
  Slice(UInt8).new(1) { value.to_u8 }
end

alias Binary = Slice(UInt8)

t = Time.now

test_unpack("small string", 1000000, String, "a" * 200)
test_unpack("small binary", 1000000, Binary, bytes(200))
test_unpack("big string", 10000, String, "a" * 200000)
test_unpack("big binary", 10000, Binary, bytes(200000))
test_unpack("hash string string", 10000, Hash(String, String), (0..1000).reduce({} of String => String) { |h, i| h["key#{i}"] = "value#{i}"; h })
test_unpack("hash string binary", 10000, Hash(String, Binary), (0..1000).reduce({} of String => Binary) { |h, i| h["key#{i}"] = byte(i); h })
test_unpack("hash string float64", 10000, Hash(String, Float64), (0..1000).reduce({} of String => Float64) { |h, i| h["key#{i}"] = i / 10.0.to_f64; h })
test_unpack("array of strings", 10000, Array(String), Array.new(1000) { |i| "data#{i}" })
test_unpack("array of binaries", 10000, Array(Binary), Array.new(1000) { |i| byte(i) })
test_unpack("array of floats", 20000, Array(Float64), Array.new(3000) { |i| i / 10.0 })

ints = [1, -1, 0x21, -0x21, 128, -128, -0x8000, 0x8000, 0xFFFF, -0xFFFF, -0x80000000, 0x80000000, -9223372036854775808, 9223372036854775807, 4294967295, -4294967295]
test_unpack("array of mix int sizes", 2000, Array(Int64), Array.new(30000) { |i| ints[i % ints.size] })

puts "Summary time: #{Time.now - t}"
