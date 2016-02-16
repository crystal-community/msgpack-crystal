require 'msgpack'

coords = []
chars = ('a'..'z').to_a

1000000.times do
  coord = {
    'x' => rand,
    'y' => rand,
    'z' => rand,
    'name' => "#{chars.sample(6).join} #{rand(10000)}",
    'opts' => {'1' => [1, true]},
  }
  coords << coord
end

t = Time.now
msg = {'coordinates' => coords, 'info' => "some info"}.to_msgpack
p Time.now - t

File.open("1.msg", 'w') { |f| f.write(msg) }
