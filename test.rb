require 'msgpack'

STDOUT << (1_000_000.times.collect do |i|
  1.1
end.to_msgpack)

