require "../src/msgpack"

def test_unpack(name, count, data)
  slice = MessagePack::Packer.new.write(data).to_slice
  t = Time.now
  print name
  res = 0
  count.times do |i|
    obj = yield(slice)
    res += obj.size
  end
  puts " = #{res}, #{Time.now - t}"
end

def test_unpack_string(name, count, data)
  test_unpack(name, count, data) do |slice|
    MessagePack::Unpacker.new(slice).read_string
  end
end

def test_unpack_hash(name, count, data)
  test_unpack(name, count, data) do |slice|
    MessagePack::Unpacker.new(slice).read_hash
  end
end

def test_unpack_array(name, count, data)
  test_unpack(name, count, data) do |slice|
    MessagePack::Unpacker.new(slice).read_array
  end
end

t = Time.now

test_unpack_string("small string", 1000000, "a" * 200)
test_unpack_string("big string", 10000, "a" * 200000)
test_unpack_hash("hash string string", 10000, (0..1000).reduce({} of String => String) { |h, i| h["key#{i}"] = "value#{i}"; h })
test_unpack_hash("hash string float64", 10000, (0..1000).reduce({} of String => Float64) { |h, i| h["key#{i}"] = i / 10.0.to_f64; h })
test_unpack_array("array of strings", 10000, Array.new(1000) { |i| "data#{i}" })
test_unpack_array("array of floats", 20000, Array.new(3000) { |i| i / 10.0 })

puts "Summary time: #{Time.now - t}"
