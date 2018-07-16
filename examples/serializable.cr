require "../src/msgpack"

class Location
  include MessagePack::Serializable

  property lat : Float64
  property lng : Float64
end

class House
  include MessagePack::Serializable

  property address : String
  property location : Location?
end

house = House.from_msgpack({address: "Road12", location: {lat: 12.3, lng: 34.5}}.to_msgpack)
p house
# => <House:0x1b06de0 @address="Road12", @location=#<Location:0x1b06dc0 @lat=12.3, @lng=34.5>>

p house.to_msgpack
# => Bytes[130, 167, 97, 100, 100, 114, 101, 115, 115, 166, 82, 111, 97, 100, ...

house.address = "Something"
house = House.from_msgpack(house.to_msgpack)
p house
# => #<House:0x13f0d80 @address="Something", @location=#<Location:0x13f0d60 @lat=12.3, @lng=34.5>>

house = House.from_msgpack({"address" => "Crystal Road 1234"}.to_msgpack)
p house
# => <House:0x1b06d80 @address="Crystal Road 1234", @location=nil>
