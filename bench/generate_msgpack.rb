require 'msgpack'

x = []

1000000.times do
  h = {
    'x' => rand,
    'y' => rand,
    'z' => rand,
    'name' => ('a'..'z').to_a.shuffle[0..5].join + ' ' + rand(10000).to_s,
    'opts' => {'1' => [1, true]},
  }
  x << h
end

File.open("1.msg", 'w') { |f| f.write({'coordinates' => x, 'info' => "some info"}.to_msgpack) }
