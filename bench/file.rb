require 'msgpack'

text = File.read('1.msg')

t = Time.now

jobj = MessagePack.unpack(text)
coordinates = jobj['coordinates']
len = coordinates.length
x = y = z = 0

coordinates.each do |coord|
  x += coord['x']
  y += coord['y']
  z += coord['z']
end

p x / len
p y / len
p z / len

p Time.now - t
