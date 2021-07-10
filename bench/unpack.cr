require "../src/msgpack"

module Global
  @@summary_unpacked = 0_u64

  def self.summary_unpacked
    @@summary_unpacked
  end

  def self.summary_unpacked=(value)
    @@summary_unpacked = value
  end
end

def test_unpack(name, count, klass, data, *, zero_copy = false)
  slice = data.to_msgpack
  t = Time.local
  print name
  res = 0
  count.times do |i|
    obj = klass.from_msgpack(slice, zero_copy: zero_copy)
    res += obj.is_a?(String) ? obj.bytesize : obj.size
  end
  Global.summary_unpacked += res
  puts " = #{res}, #{Time.local - t}"
end

def bytes(size : Int32) : Bytes
  Bytes.new(size) { |i| (i % 256).to_u8 }
end

def byte(value : Int32) : Bytes
  Bytes.new(1) { (value % 256).to_u8 }
end

alias Binary = Bytes

t = Time.local

test_unpack("small string", 1000000, String, "a" * 200)
test_unpack("small binary", 1000000, Binary, bytes(200))
test_unpack("big string", 10000, String, "a" * 200000)
test_unpack("big binary", 10000, Binary, bytes(200000))
test_unpack("big binary(zc)", 10000, Binary, bytes(200000), zero_copy: true)
test_unpack("hash string string", 10000, Hash(String, String), (0..1000).reduce({} of String => String) { |h, i| h["key#{i}"] = "value#{i}"; h })
test_unpack("hash string binary", 10000, Hash(String, Binary), (0..1000).reduce({} of String => Binary) { |h, i| h["key#{i}"] = byte(i); h })
test_unpack("hash string binary(zc)", 10000, Hash(String, Binary), (0..1000).reduce({} of String => Binary) { |h, i| h["key#{i}"] = byte(i); h }, zero_copy: true)
test_unpack("hash string float64", 10000, Hash(String, Float64), (0..1000).reduce({} of String => Float64) { |h, i| h["key#{i}"] = i / 10.0.to_f64; h })
test_unpack("array of strings", 10000, Array(String), Array.new(1000) { |i| "data#{i}" })
test_unpack("array of binaries", 10000, Array(Binary), Array.new(1000) { |i| byte(i) })
test_unpack("array of binaries(zc)", 10000, Array(Binary), Array.new(1000) { |i| byte(i) }, zero_copy: true)
test_unpack("array of floats", 20000, Array(Float64), Array.new(3000) { |i| i / 10.0 })

ints = [1, -1, 0x21, -0x21, 128, -128, -0x8000, 0x8000, 0xFFFF, -0xFFFF, -0x80000000, 0x80000000, -9223372036854775808, 9223372036854775807, 4294967295, -4294967295]
test_unpack("array of mix int sizes", 2000, Array(Int64), Array.new(30000) { |i| ints[i % ints.size] })

data = [Array.new(30) { |i| i }, Array.new(30) { |i| i.to_s }, (0..30).reduce({} of Int32 => String) { |h, i| h[i] = i.to_s; h }, 1, "1"]
test_unpack("array of mix of data", 200, Array(Array(Int32) | Array(String) | Hash(Int32, String) | Int32 | String), Array.new(10000) { |i| data[i % data.size] })

puts "Summary unpacked size: #{Global.summary_unpacked}"
puts "Summary time: #{Time.local - t}"
