require "../src/msgpack"

module Global
  @@summary_packed = 0_u64

  def self.summary_packed
    @@summary_packed
  end

  def self.summary_packed=(value)
    @@summary_packed = value
  end
end

def test_pack(name, count, data)
  t = Time.local
  print name
  res = 0
  count.times do |i|
    res += data.to_msgpack.size
  end
  puts " = #{res}, #{Time.local - t}"
  Global.summary_packed += res
end

def bytes(size : Int32) : Bytes
  Bytes.new(size) { |i| (i % 256).to_u8 }
end

def byte(value : Int32) : Bytes
  Bytes.new(1) { (value % 256).to_u8 }
end

alias Binary = Bytes

t = Time.local

test_pack("small string", 1000000, "a" * 200)
test_pack("small binary", 1000000, bytes(200))
test_pack("big string", 10000, "a" * 200000)
test_pack("big binary", 10000, bytes(200000))
test_pack("hash string string", 10000, (0..1000).reduce({} of String => String) { |h, i| h["key#{i}"] = "value#{i}"; h })
test_pack("hash string binary", 10000, (0..1000).reduce({} of String => Binary) { |h, i| h["key#{i}"] = byte(i); h })
test_pack("hash string float64", 10000, (0..1000).reduce({} of String => Float64) { |h, i| h["key#{i}"] = i / 10.0.to_f64; h })
test_pack("array of strings", 10000, Array.new(1000) { |i| "data#{i}" })
test_pack("array of binaries", 10000, Array.new(1000) { |i| byte(i) })
test_pack("array of floats", 20000, Array.new(3000) { |i| i / 10.0 })

ints = [1, -1, 0x21, -0x21, 128, -128, -0x8000, 0x8000, 0xFFFF, -0xFFFF, -0x80000000, 0x80000000, -9223372036854775808, 9223372036854775807, 4294967295, -4294967295]
test_pack("array of mix int sizes", 2000, Array.new(30000) { |i| ints[i % ints.size] })

data = [Array.new(30) { |i| i }, Array.new(30) { |i| i.to_s }, (0..30).reduce({} of Int32 => String) { |h, i| h[i] = i.to_s; h }, 1, "1"]
test_pack("array of mix of data", 200, Array.new(10000) { |i| data[i % data.size] })

puts "Summary packed size: #{Global.summary_packed} bytes"
puts "Summary time: #{Time.local - t}"
