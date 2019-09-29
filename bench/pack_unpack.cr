require "../src/msgpack"

r = Random.new(1234_u64, 1234_u64)

class Stat
  @@d1 : Time::Span = Time.local - Time.local
  @@d2 : Time::Span = Time.local - Time.local

  def self.d1
    @@d1
  end

  def self.d2
    @@d2
  end

  def self.incd1(v)
    @@d1 += v
  end

  def self.incd2(v)
    @@d2 += v
  end
end

def check(elements_count, unpack_count, pack_count, klass : T.class) forall T
  GC.collect

  t = Time.local
  io = IO::Memory.new
  unpack_count.times do
    io = IO::Memory.new
    elements_count.times do |i|
      yield(i).to_msgpack(io)
    end
  end
  dt = Time.local - t

  t = Time.local
  unpack_count.times do
    io.rewind
    unpacker = MessagePack::IOUnpacker.new(io)
    elements_count.times do
      klass.new(unpacker)
    end
  end

  dt2 = Time.local - t
  puts "check #{klass.to_s.rjust(50)}: pack: #{dt}, unpack: #{dt2}"

  GC.collect

  Stat.incd1(dt)
  Stat.incd2(dt2)
end

t1 = Time.local

elements_count = (ARGV[0]? || 1000000).to_i
unpack_count = (ARGV[1]? || 1).to_i
pack_count = (ARGV[2]? || 1).to_i

check(elements_count * 2, unpack_count, pack_count, Nil) { nil }
check(elements_count * 2, unpack_count, pack_count, Bool) { |i| i % 2 == 1 }
check(elements_count, unpack_count, pack_count, Float64) { r.rand }
check(elements_count, unpack_count, pack_count, UInt64) { |i| i }

ints = [1, -1, 0x21, -0x21, 128, -128, -0x8000, 0x8000, 0xFFFF, -0xFFFF, -0x80000000, 0x80000000, -9223372036854775808, 9223372036854775807, 4294967295, -4294967295]
check(elements_count, unpack_count, pack_count, Int64) { |i| ints[i % ints.size] }

check(elements_count, unpack_count, pack_count, String) { |i| "a" * (i % 10 + 1) }
check(elements_count, unpack_count, pack_count, Slice) { |i| ("a" * (i % 10 + 1)).to_slice }

check(elements_count, unpack_count, pack_count, Int32 | String | Nil) do |i|
  case i % 3
  when 0
    nil
  when 1
    "bla"
  when 2
    i
  end
end

check(elements_count // 40, unpack_count, pack_count, Array(Int32) | Hash(Bool, Int32)) do |i|
  case i % 2
  when 0
    [i, i + 1, i - 1]
  when 1
    {true => i, false => i + 1}
  end
end

check(elements_count // 3, unpack_count, pack_count, Array(Int32)) { |i| Array.new(i % 3 + 1) { |j| j } }
check(elements_count // 5, unpack_count, pack_count, Hash(Int32, Float64)) do |i|
  h = {} of Int32 => Float64; 3.times { |j| h[i] = j / i.to_f }; h
end

check(elements_count // 5, unpack_count, pack_count, Hash(String, Float64 | String | Array(Int32))) do |i|
  h = Hash(String, Float64 | String | Array(Int32)).new

  case i % 3
  when 0
    h["key#{i}"] = r.rand
  when 1
    h["key#{i}"] = "what#{i}"
  when 2
    h["key#{i}"] = [i, i + 1, i - 1]
  end

  h
end

puts "-" * 50
puts "summa #{(Time.local - t1).to_s.rjust(50)}: pack: #{Stat.d1}, unpack: #{Stat.d2}"
puts "-" * 50
