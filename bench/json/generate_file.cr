require "json"

class Coord
  JSON.mapping({
    x:    Float64,
    y:    Float64,
    z:    Float64,
    name: String,
    opts: Hash(String, Tuple(Int32, Bool)),
  })

  def initialize(@x, @y, @z, @name, @opts)
  end
end

coords = [] of Coord
chars = ('a'..'z').to_a

1000000.times do
  coord = Coord.new rand, rand, rand, "#{chars.sample(6).join} #{rand(10000)}", {"1" => {1, true}}
  coords << coord
end

t = Time.now
msg = {"coordinates" => coords, "info" => "some info"}.to_json
p "#{msg.size} bytes"
p Time.now - t

File.open("1.js", "w") { |f| f.print(msg) }
