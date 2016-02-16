require "../src/message_pack"

class Location
  MessagePack.mapping({
    lat: Float64,
    lng: Float64,
  })
end

class House
  MessagePack.mapping({
    address:  String,
    location: {type: Location, nilable: true},
  })
end

house = House.from_msgpack({"address" => "Crystal Road 1234", "location" => {"lat" => 12.3, "lng" => 34.5}}.to_msgpack)
p house # <House:0x1b06de0 @address="Crystal Road 1234", @location=#<Location:0x1b06dc0 @lat=12.3, @lng=34.5>>

house.address = "Something"
house = House.from_msgpack(house.to_msgpack)
p house # #<House:0x13f0d80 @address="Something", @location=#<Location:0x13f0d60 @lat=12.3, @lng=34.5>>

house = House.from_msgpack({"address" => "Crystal Road 1234"}.to_msgpack)
p house # <House:0x1b06d80 @address="Crystal Road 1234", @location=nil>
