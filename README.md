# MessagePack
[![Build Status](https://github.com/crystal-community/msgpack-crystal/actions/workflows/ci.yml/badge.svg)](https://github.com/crystal-community/msgpack-crystal/actions/workflows/ci.yml?query=branch%3Amaster+event%3Apush)

MessagePack implementation in Crystal.

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  msgpack:
    github: crystal-community/msgpack-crystal
```

## Usage

```crystal
require "msgpack"

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
```

## More Examples

[examples](https://github.com/benoist/msgpack-crystal/tree/master/examples)

## Msgpack-RPC

[implemented by simple_rpc shard](https://github.com/kostya/simple_rpc)

## Copyright

Copyright 2015 Benoist Claassen

_Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License You may obtain a copy of the License at_

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

_Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License._
