require "json"

$summary_packed = 0

def test_pack(name, count, data)
  t = Time.now
  print name
  res = 0
  count.times do |i|
    res += data.to_json.bytesize
  end
  puts " = #{res}, #{Time.now - t}"
  $summary_packed += res
end

t = Time.now

test_pack("small string", 1000000, "a" * 200)
test_pack("big string", 10000, "a" * 200000)
test_pack("hash string string", 10000, (0..1000).reduce({}) { |h, i| h["key#{i}"] = "value#{i}"; h })
test_pack("hash string float64", 10000, (0..1000).reduce({}) { |h, i| h["key#{i}"] = i / 10.0; h })
test_pack("array of strings", 10000, Array.new(1000) { |i| "data#{i}" })
test_pack("array of floats", 20000, Array.new(3000) { |i| i / 10.0 })

ints = [1, -1, 0x21, -0x21, 128, -128, -0x8000, 0x8000, 0xFFFF, -0xFFFF, -0x80000000, 0x80000000, -9223372036854775808, 9223372036854775807, 4294967295, -4294967295]
test_pack("array of mix int sizes", 2000, Array.new(30000) { |i| ints[i % ints.size] })

puts "Summary packed size: #{$summary_packed / 1024 / 1024} Mb"
puts "Summary time: #{Time.now - t}"
