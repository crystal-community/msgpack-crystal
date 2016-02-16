require "../src/msgpack"

struct Coordinate
  MessagePack.mapping({
    x: Float64,
    y: Float64,
    z: Float64,
  })
end

class Coordinates
  MessagePack.mapping({
    coordinates: {type: Array(Coordinate)},
  })
end

text = File.read("1.msg")

t = Time.now

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

p Time.now - t
