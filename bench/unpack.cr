require "../src/msgpack"

def test_unpack(name, count, data)
  packed = MessagePack::Packer.new.write(data).to_slice

  t = Time.now
  print name
  count.times do |i|
    MessagePack::Unpacker.new(packed).read
  end
  puts " = #{Time.now - t}"
end

t = Time.now

test_unpack("small string", 1000000, "a" * 200)
test_unpack("big string", 10000, "a" * 200000)
test_unpack("hash string string", 10000, (0..1000).reduce({} of String => String) { |h, i| h["key#{i}"] = "value#{i}"; h })
test_unpack("hash string float64", 10000, (0..1000).reduce({} of String => Float64) { |h, i| h["key#{i}"] = i / 10.0.to_f64; h })
test_unpack("array of strings", 10000, Array.new(1000) { |i| "data#{i}" })
test_unpack("array of floats", 20000, Array.new(3000) { |i| i / 10.0 })

puts "Summary time: #{Time.now - t}"
