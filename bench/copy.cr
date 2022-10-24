require "../src/msgpack"

def copy1(io1, io2)
  obj = MessagePack::IOUnpacker.new(io1).read
  obj.to_msgpack(io2)
end

def copy2(io1, io2)
  MessagePack::Copy.new(io1, io2).copy_object
end

def test_obj_copy(copy_name, test_name, n, type, obj)
  io1 = IO::Memory.new
  obj.to_msgpack(io1)
  io1.rewind

  io2 = IO::Memory.new

  t = Time.local
  n.times do
    io1.rewind
    io2.clear

    yield io1, io2
  end

  t2 = Time.local

  io2.rewind
  res = type.from_msgpack(io2)
  puts "#{copy_name}[#{test_name}]: #{t2 - t}"

  io1.rewind
  io2.rewind
  unless io1.to_slice == io2.to_slice
    puts "Warning, bad copy"
  end
end

def test_obj(test_name, n, type, obj)
  test_obj_copy("copy_dumb", test_name, n, type, obj) { |io1, io2| copy1(io1, io2) }
  test_obj_copy("copy_fast", test_name, n, type, obj) { |io1, io2| copy2(io1, io2) }
end

def bytes(size : Int32) : Bytes
  Bytes.new(size) { |i| (i % 256).to_u8 }
end

def byte(value : Int32) : Bytes
  Bytes.new(1) { (value % 256).to_u8 }
end

t = Time.local

test_obj("small string", 1000000, String, "a" * 200)
test_obj("small binary", 1000000, Bytes, bytes(200))
test_obj("big string", 10000, String, "a" * 200000)
test_obj("big binary", 10000, Bytes, bytes(200000))
test_obj("hash string string", 10000, Hash(String, String), (0..1000).reduce({} of String => String) { |h, i| h["key#{i}"] = "value#{i}"; h })
test_obj("hash string binary", 10000, Hash(String, Bytes), (0..1000).reduce({} of String => Bytes) { |h, i| h["key#{i}"] = byte(i); h })
test_obj("hash string float64", 10000, Hash(String, Float64), (0..1000).reduce({} of String => Float64) { |h, i| h["key#{i}"] = i / 10.0.to_f64; h })
test_obj("array of strings", 10000, Array(String), Array.new(1000) { |i| "data#{i}" })
test_obj("array of binaries", 10000, Array(Bytes), Array.new(1000) { |i| byte(i) })
test_obj("array of floats", 20000, Array(Float64), Array.new(3000) { |i| i / 10.0 })

ints = [1, -1, 0x21, -0x21, 128, -128, -0x8000, 0x8000, 0xFFFF, -0xFFFF, -0x80000000, 0x80000000, -9223372036854775808, 9223372036854775807, 4294967295, -4294967295]
test_obj("array of mix int sizes", 2000, Array(Int64), Array.new(30000) { |i| ints[i % ints.size] })

data = [Array.new(30) { |i| i }, Array.new(30) { |i| i.to_s }, (0..30).reduce({} of Int32 => String) { |h, i| h[i] = i.to_s; h }, 1, "1"]
test_obj("array of mix of data", 200, Array(Array(Int32) | Array(String) | Hash(Int32, String) | Int32 | String), Array.new(10000) { |i| data[i % data.size] })

puts "Summary time: #{Time.local - t}"
