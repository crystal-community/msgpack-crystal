require 'json'

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
msg = {'coordinates' => coords, 'info' => "some info"}.to_json
p "#{msg.size} bytes"
p Time.now - t

File.open("1.js", 'w') { |f| f.write(msg) }
