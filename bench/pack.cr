require "../src/msgpack"

def test_pack(name, count, &block : Int32 -> Slice(UInt8))
  t = Time.now
  print name
  res = 0
  count.times do |i|
    res += block.call(i).size
  end
  puts " = #{res}, #{Time.now - t}"
end

t = Time.now

# =============================================

s = "a" * 200
test_pack("small string", 1000000) do
  MessagePack::Packer.new.write(s).to_slice
end

# =============================================

s = "a" * 200000
test_pack("big string", 10000) do
  MessagePack::Packer.new.write(s).to_slice
end

# =============================================

h = {} of String => String
1000.times do |i|
  h["key#{i}"] = "value#{i}"
end

test_pack("hash string string", 10000) do
  MessagePack::Packer.new.write(h).to_slice
end

# =============================================

h2 = {} of String => Float64
1000.times do |i|
  h2["key#{i}"] = i / 10.0.to_f64
end

test_pack("hash string float64", 10000) do
  MessagePack::Packer.new.write(h2).to_slice
end

# =============================================

arr = Array.new(1000) { |i| "data#{i}" }
test_pack("array of strings", 10000) do
  MessagePack::Packer.new.write(arr).to_slice
end

# =============================================

arr = Array.new(3000) { |i| i / 10.0 }
test_pack("array of floats", 20000) do
  MessagePack::Packer.new.write(arr).to_slice
end

puts "Summary time: #{Time.now - t}"
