require "../src/msgpack"

struct Coordinate
  include MessagePack::Serializable
  getter x : Float64
  getter y : Float64
  getter z : Float64
end

class Coordinates
  include MessagePack::Serializable
  getter coordinates : Array(Coordinate)
end

text = File.read("1.msg")

t = Time.local

coordinates = Coordinates.from_msgpack(text).coordinates
len = coordinates.size
x = y = z = 0

coordinates.each do |e|
  x += e.x
  y += e.y
  z += e.z
end

p x / len
p y / len
p z / len

p Time.local - t
