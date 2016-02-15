require "msgpack"
# gem install msgpack

def test_pack(name, count, &block)
  t = Time.now
  print name
  res = 0
  count.times do |i|
    res += block.call(i).bytesize
  end
  puts " = #{res}, #{Time.now - t}"
end

t = Time.now

# =============================================

s = "a" * 200
test_pack("small string", 1000000) do
  s.to_msgpack
end

# =============================================

s = "a" * 200000
test_pack("big string", 10000) do
  s.to_msgpack
end

# =============================================

h = {}
1000.times do |i|
  h["key#{i}"] = "value#{i}"
end

test_pack("hash string string", 10000) do
  h.to_msgpack
end

# =============================================

h2 = {}
1000.times do |i|
  h2["key#{i}"] = i / 10.0
end

test_pack("hash string float64", 10000) do
  h2.to_msgpack
end

# =============================================

arr = Array.new(1000) { |i| "data#{i}" }
test_pack("array of strings", 10000) do
  arr.to_msgpack
end

# =============================================

arr = Array.new(3000) { |i| i / 10.0 }
test_pack("array of floats", 20000) do
  arr.to_msgpack
end

puts "Summary time: #{Time.now - t}"
