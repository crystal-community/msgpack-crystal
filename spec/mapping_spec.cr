require "./spec_helper"
require "base64"

class MessagePackPerson
  MessagePack.mapping({
    name: {type: String},
    age:  {type: Int32, nilable: true},
  })

  def_equals name, age

  def initialize(@name : String)
  end
end

class StrictMessagePackPerson
  MessagePack.mapping({
    name: {type: String},
    age:  {type: Int32, nilable: true},
  }, true)
end

class MessagePackPersonEmittingNull
  MessagePack.mapping({
    name: {type: String},
    age:  {type: Int32, nilable: true},
  })
end

class MessagePackWithBool
  MessagePack.mapping({
    value: {type: Bool},
  })
end

class MessagePackWithTime
  MessagePack.mapping({
    value: {type: Time, converter: Time::Format.new("%F %T")},
  })
end

class MessagePackWithNilableTime
  MessagePack.mapping({
    value: {type: Time, nilable: true, converter: Time::Format.new("%F")},
  })

  def initialize
  end
end

class MessagePackWithNilableTimeEmittingNull
  MessagePack.mapping({
    value: {type: Time, nilable: true, converter: Time::Format.new("%F")},
  })

  def initialize
  end
end

class MessagePackWithSimpleMapping
  MessagePack.mapping({name: String, age: Int32})
end

class MessagePackWithKeywordsMapping
  MessagePack.mapping({end: Int32, abstract: Int32})
end

class MessagePackWithProblematicKeys
  MessagePack.mapping({
    key:  Int32,
    pull: Int32,
  })
end

class MessagePackWithSet
  MessagePack.mapping({set: Set(String)})
end

class MessagePackWithDefaults
  MessagePack.mapping({
    a: {type: Int32, default: 11},
    b: {type: String, default: "Haha"},
    c: {type: Bool, default: true},
    d: {type: Bool, default: false},
    e: {type: Bool, nilable: true, default: false},
    f: {type: Int32, nilable: true, default: 1},
    g: {type: Int32, nilable: true, default: nil},
    h: {type: Array(Int32), default: [1, 2, 3]},
  })
end

struct MessagePackCoordinate
  MessagePack.mapping({
    x: Float64,
    y: Float64,
    z: Float64,
  })
end

class MessagePackCoordinates
  MessagePack.mapping({
    coordinates: {type: Array(MessagePackCoordinate)},
  })
end

class MessagePackKVS
  MessagePack.mapping({
    key: String,
    val: {type: Slice(UInt8), nilable: true},
  })
end

class StrictMessagePackKVS
  MessagePack.mapping({
    key: String,
    val: {type: Slice(UInt8), nilable: true},
  }, true)
end

describe "MessagePack mapping" do
  it "parses person" do
    person = MessagePackPerson.from_msgpack({"name" => "John", "age" => 30}.to_msgpack)
    person.should be_a(MessagePackPerson)
    person.name.should eq("John")
    person.age.should eq(30)
  end

  it "parses person without age" do
    person = MessagePackPerson.from_msgpack({"name": "John"}.to_msgpack)
    person.should be_a(MessagePackPerson)
    person.name.should eq("John")
    person.name.size.should eq(4) # This verifies that name is not nilable
    person.age.should be_nil
  end

  it "parses array of people" do
    people = Array(MessagePackPerson).from_msgpack([{"name" => "John"}, {"name" => "Doe"}].to_msgpack)
    people.size.should eq(2)
  end

  it "does to_msgpack" do
    person = MessagePackPerson.from_msgpack({"name" => "John", "age" => 30}.to_msgpack)
    person2 = MessagePackPerson.from_msgpack(person.to_msgpack)
    person2.should eq(person)
  end

  it "parses person with unknown attributes" do
    person = MessagePackPerson.from_msgpack({"name" => "John", "age" => 30, "foo" => "bar"}.to_msgpack)
    person.should be_a(MessagePackPerson)
    person.name.should eq("John")
    person.age.should eq(30)
  end

  it "parses strict person with unknown attributes" do
    expect_raises MessagePack::Error, "unknown msgpack attribute: foo" do
      StrictMessagePackPerson.from_msgpack({"name" => "John", "age" => 30, "foo" => "bar"}.to_msgpack)
    end
  end

  it "raises if non-nilable attribute is nil" do
    expect_raises MessagePack::Error, "missing msgpack attribute: name" do
      MessagePackPerson.from_msgpack({"age" => 30}.to_msgpack)
    end
  end

  it "emits null when doing to_msgpack" do
    person = MessagePackPersonEmittingNull.from_msgpack({"name" => "John"}.to_msgpack)
    person.to_msgpack.should eq as_slice(UInt8[130, 164, 110, 97, 109, 101, 164, 74, 111, 104, 110, 163, 97, 103, 101, 192])
  end

  it "doesn't raises on false value when not-nil" do
    msgpack = MessagePackWithBool.from_msgpack({"value" => false}.to_msgpack)
    msgpack.value.should be_false
  end

  it "parses msgpack with Time::Format converter" do
    msg = {"value" => "2014-10-31 23:37:16"}.to_msgpack
    msgpack = MessagePackWithTime.from_msgpack(msg)
    msgpack.value.should be_a(Time)
    msgpack.value.to_s.should eq("2014-10-31 23:37:16")
    msgpack.to_msgpack.should eq(msg)
  end

  it "allows setting a nilable property to nil" do
    person = MessagePackPerson.new("John")
    person.age = 1
    person.age = nil
  end

  it "parses simple mapping" do
    person = MessagePackWithSimpleMapping.from_msgpack({"name" => "John", "age" => 30}.to_msgpack)
    person.should be_a(MessagePackWithSimpleMapping)
    person.name.should eq("John")
    person.age.should eq(30)
  end

  it "outputs with converter when nilable" do
    msgpack = MessagePackWithNilableTime.new
    msgpack.to_msgpack.should eq(as_slice(UInt8[129, 165, 118, 97, 108, 117, 101, 192]))
  end

  it "outputs with converter when nilable" do
    msgpack = MessagePackWithNilableTimeEmittingNull.new
    msgpack.to_msgpack.should eq(as_slice(UInt8[129, 165, 118, 97, 108, 117, 101, 192]))
  end

  it "parses msgpack with keywords" do
    msgpack = MessagePackWithKeywordsMapping.from_msgpack({"end" => 1, "abstract" => 2}.to_msgpack)
    msgpack.end.should eq(1)
    msgpack.abstract.should eq(2)
  end

  it "parses msgpack with problematic keys" do
    msgpack = MessagePackWithProblematicKeys.from_msgpack({"key" => 1, "pull" => 2}.to_msgpack)
    msgpack.key.should eq(1)
    msgpack.pull.should eq(2)
  end

  it "parses msgpack array as set" do
    msgpack = MessagePackWithSet.from_msgpack({"set" => ["a", "a", "b"]}.to_msgpack)
    msgpack.set.should eq(Set(String){"a", "b"})
  end

  describe "(binary support)" do
    binary_data = Slice(UInt8).new(UInt8[0x08, 0xE7].to_unsafe, 2)
    it "parses binary data" do
      kvs = MessagePackKVS.from_msgpack({"key" => "a", "val" => binary_data}.to_msgpack)
      kvs.should be_a(MessagePackKVS)
      kvs.key.should eq("a")
      kvs.val.should eq(binary_data)
    end

    it "parses binary data with unknown attributes" do
      kvs = MessagePackKVS.from_msgpack({"key" => "a", "val" => binary_data, "foo" => "bar"}.to_msgpack)
      kvs.should be_a(MessagePackKVS)
      kvs.key.should eq("a")
      kvs.val.should eq(binary_data)
    end

    it "parses binary data without attributes" do
      kvs = MessagePackKVS.from_msgpack({"key" => "a"}.to_msgpack)
      kvs.should be_a(MessagePackKVS)
      kvs.key.should eq("a")
      kvs.val.should eq(nil)
    end

    it "parses binary data with nil value" do
      kvs = MessagePackKVS.from_msgpack({"key" => "a", "val" => nil}.to_msgpack)
      kvs.should be_a(MessagePackKVS)
      kvs.key.should eq("a")
      kvs.val.should eq(nil)
    end

    it "parses strict binary data" do
      kvs = StrictMessagePackKVS.from_msgpack({"key" => "a", "val" => binary_data}.to_msgpack)
      kvs.should be_a(StrictMessagePackKVS)
      kvs.key.should eq("a")
      kvs.val.should eq(binary_data)
    end

    it "parses strict binary data with unknown attributes" do
      expect_raises MessagePack::Error, "unknown msgpack attribute: foo" do
        StrictMessagePackKVS.from_msgpack({"key" => "a", "val" => binary_data, "foo" => "bar"}.to_msgpack)
      end
    end

    it "parses strict binary data without attributes" do
      kvs = StrictMessagePackKVS.from_msgpack({"key" => "a"}.to_msgpack)
      kvs.should be_a(StrictMessagePackKVS)
      kvs.key.should eq("a")
      kvs.val.should eq(nil)
    end

    it "parses strict binary data with nil value" do
      kvs = StrictMessagePackKVS.from_msgpack({"key" => "a", "val" => nil}.to_msgpack)
      kvs.should be_a(StrictMessagePackKVS)
      kvs.key.should eq("a")
      kvs.val.should eq(nil)
    end
  end

  describe "parses msgpack with defaults" do
    it "pack unpack" do
      msg = {"a" => 1, "b" => "bla"}.to_msgpack
      obj = MessagePackWithDefaults.from_msgpack(msg)
      obj.a.should eq 1
      obj.c.should eq true
      msg2 = obj.to_msgpack
      msg.should_not eq msg2

      obj = MessagePackWithDefaults.from_msgpack(msg2)
      obj.a.should eq 1
      obj.c.should eq true
    end

    it "mixed" do
      msgpack = MessagePackWithDefaults.from_msgpack({"a" => 1, "b" => "bla"}.to_msgpack)
      msgpack.a.should eq 1
      msgpack.b.should eq "bla"

      msgpack = MessagePackWithDefaults.from_msgpack({"a" => 1}.to_msgpack)
      msgpack.a.should eq 1
      msgpack.b.should eq "Haha"

      msgpack = MessagePackWithDefaults.from_msgpack({"b" => "bla"}.to_msgpack)
      msgpack.a.should eq 11
      msgpack.b.should eq "bla"

      msgpack = MessagePackWithDefaults.from_msgpack(({} of String => String).to_msgpack)
      msgpack.a.should eq 11
      msgpack.b.should eq "Haha"

      msgpack = MessagePackWithDefaults.from_msgpack({"a" => nil, "b" => nil}.to_msgpack)
      msgpack.a.should eq 11
      msgpack.b.should eq "Haha"
    end

    it "bool" do
      msgpack = MessagePackWithDefaults.from_msgpack(({} of String => String).to_msgpack)
      msgpack.c.should eq true
      typeof(msgpack.c).should eq Bool
      msgpack.d.should eq false
      typeof(msgpack.d).should eq Bool

      msgpack = MessagePackWithDefaults.from_msgpack({"c" => false}.to_msgpack)
      msgpack.c.should eq false
      msgpack = MessagePackWithDefaults.from_msgpack({"c" => true}.to_msgpack)
      msgpack.c.should eq true

      msgpack = MessagePackWithDefaults.from_msgpack({"d" => false}.to_msgpack)
      msgpack.d.should eq false
      msgpack = MessagePackWithDefaults.from_msgpack({"d" => true}.to_msgpack)
      msgpack.d.should eq true
    end

    it "with nilable" do
      msgpack = MessagePackWithDefaults.from_msgpack(({} of String => String).to_msgpack)

      msgpack.e.should eq false
      typeof(msgpack.e).should eq(Bool | Nil)

      msgpack.f.should eq 1
      typeof(msgpack.f).should eq(Int32 | Nil)

      msgpack.g.should eq nil
      typeof(msgpack.g).should eq(Int32 | Nil)

      msgpack = MessagePackWithDefaults.from_msgpack({"e" => false}.to_msgpack)
      msgpack.e.should eq false
      msgpack = MessagePackWithDefaults.from_msgpack({"e" => true}.to_msgpack)
      msgpack.e.should eq true
    end

    it "create new array every time" do
      msgpack = MessagePackWithDefaults.from_msgpack(({} of String => String).to_msgpack)
      msgpack.h.should eq [1, 2, 3]
      msgpack.h << 4
      msgpack.h.should eq [1, 2, 3, 4]

      msgpack = MessagePackWithDefaults.from_msgpack(({} of String => String).to_msgpack)
      msgpack.h.should eq [1, 2, 3]
    end
  end

  it "coordinates" do
    data = Base64.decode("gqtjb29yZGluYXRlc5KFoXjLP9CCVH9IMu6hecs/1TGvKza6XKF6yz/rkkVzHwTxpG5hbWWrd3lzcnF4IDM4NTGkb3B0c4GhMZIBw4WheMs/34Wk1YNbGqF5yz/Wjbls2JVWoXrLP849VOX0i/ikbmFtZatrdnFuenIgMzk0NaRvcHRzgaExkgHDpGluZm+pc29tZSBpbmZv")
    obj = MessagePackCoordinates.from_msgpack(data)
    obj.coordinates.size.should eq 2
    coord = obj.coordinates[0]
    coord.x.should be >= 0
    coord.x.should be <= 1
    coord.y.should be >= 0
    coord.y.should be <= 1
    coord.z.should be >= 0
    coord.z.should be <= 1
  end
end
