require "../src/msgpack"

class Coord
  include MessagePack::Serializable
  @x : Float64
  @y : Float64
  @z : Float64
  @name : String
  @opts : Hash(String, Tuple(Int32, Bool))

  def initialize(@x, @y, @z, @name, @opts)
  end
end

coords = [] of Coord
chars = ('a'..'z').to_a

1000000.times do
  coord = Coord.new rand, rand, rand, "#{chars.sample(6).join} #{rand(10000)}", {"1" => {1, true}}
  coords << coord
end

t = Time.local
msg = {"coordinates" => coords, "info" => "some info"}.to_msgpack
p "#{msg.size} bytes"
p Time.local - t

File.open("1.msg", "w") { |f| f.write(msg) }
