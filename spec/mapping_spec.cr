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

class NumbersMessagePack
  MessagePack.mapping({
    int8:   Int8,
    int16:  Int16,
    int32:  Int32,
    int64:  Int64,
    uint8:  Int8,
    uint16: Int16,
    uint32: Int32,
    uint64: Int64,
  })
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

class MessagePackWithUnion
  MessagePack.mapping({string_or_int: Union(Int32, String)})
end

class MessagePackWithNilUnion
  MessagePack.mapping({int_or_nil: Int32?})
end

class MessagePackWithCustomUnion
  MessagePack.mapping({custom: {type: Union(MessagePackWithTime, MessagePackWithBool)}})
end

class MessagePackWithUnions
  MessagePack.mapping({
    a: {type: Union(String, Int32), nilable: true},
    b: {type: Union(Array(Int32), Array(String)), nilable: true},
    c: {type: Union(Array(Int32), Hash(String, String)), nilable: true},
    d: {type: Union(MessagePackCoordinate, MessagePackCoordinates), nilable: true},
  })
end

class MessagePackWithEnum
  enum Level
    Debug = 0
    Info  = 1
  end
  MessagePack.mapping({level: Level})
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

  def initialize(@x : Float64, @y : Float64, @z : Float64)
  end
end

class MessagePackCoordinates
  MessagePack.mapping({
    coordinates: {type: Array(MessagePackCoordinate)},
  })
end

class MessagePackKVS
  MessagePack.mapping({
    key: String,
    val: {type: Bytes, nilable: true},
  })
end

class StrictMessagePackKVS
  MessagePack.mapping({
    key: String,
    val: {type: Bytes, nilable: true},
  }, true)
end

class UseTableClass
  MessagePack.mapping({
    name:       String,
    attributes: MessagePack::Table,
  })
end

class EmitNullsFalse
  MessagePack.mapping({
    a: String,
    b: String?,
    c: Int32?,
  }, emit_nulls: false)
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

  it "does from_msgpack with all ints" do
    numbers = NumbersMessagePack.from_msgpack({
      "int8" => 0_i8, "int16" => 0_i16, "int32" => 0_i32, "int64" => 0_i64,
      "uint8" => 0_u8, "uint16" => 0_u16, "uint32" => 0_u32, "uint64" => 0_u64,
    }.to_msgpack)
    numbers.int8.should eq 0
    numbers.int16.should eq 0
    numbers.int32.should eq 0
    numbers.int64.should eq 0
    numbers.uint8.should eq 0
    numbers.uint16.should eq 0
    numbers.uint32.should eq 0
    numbers.uint64.should eq 0
  end

  it "parses person with unknown attributes" do
    person = MessagePackPerson.from_msgpack({"name" => "John", "age" => 30, "foo" => "bar"}.to_msgpack)
    person.should be_a(MessagePackPerson)
    person.name.should eq("John")
    person.age.should eq(30)
  end

  it "parses strict person with unknown attributes" do
    expect_raises MessagePack::TypeCastError, "Unknown msgpack attribute: foo" do
      StrictMessagePackPerson.from_msgpack({"name" => "John", "age" => 30, "foo" => "bar"}.to_msgpack)
    end
  end

  it "raises if non-nilable attribute is nil" do
    expect_raises MessagePack::TypeCastError, "Missing msgpack attribute: name" do
      MessagePackPerson.from_msgpack({"age" => 30}.to_msgpack)
    end
  end

  it "emits null when doing to_msgpack" do
    person = MessagePackPersonEmittingNull.from_msgpack({"name" => "John"}.to_msgpack)
    person.to_msgpack.should eq Bytes[130, 164, 110, 97, 109, 101, 164, 74, 111, 104, 110, 163, 97, 103, 101, 192]
  end

  it "doesn't raises on false value when not-nil" do
    msgpack = MessagePackWithBool.from_msgpack({"value" => false}.to_msgpack)
    msgpack.value.should be_false
  end

  it "parses msgpack with Time::Format converter" do
    msg = {"value" => "2014-10-31 23:37:16"}.to_msgpack
    msgpack = MessagePackWithTime.from_msgpack(msg)
    msgpack.value.should be_a(Time)
    msgpack.value.to_s.should eq("2014-10-31 23:37:16 UTC")
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

  it "parses simple mapping, key is binary" do
    person = MessagePackWithSimpleMapping.from_msgpack({"name".to_slice => "John", "age".to_slice => 30}.to_msgpack)
    person.should be_a(MessagePackWithSimpleMapping)
    person.name.should eq("John")
    person.age.should eq(30)
  end

  it "outputs with converter when nilable" do
    msgpack = MessagePackWithNilableTime.new
    msgpack.to_msgpack.should eq(Bytes[129, 165, 118, 97, 108, 117, 101, 192])
  end

  it "outputs with converter when nilable" do
    msgpack = MessagePackWithNilableTimeEmittingNull.new
    msgpack.to_msgpack.should eq(Bytes[129, 165, 118, 97, 108, 117, 101, 192])
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

  it "parses msgpack with enum" do
    msgpack = MessagePackWithEnum.from_msgpack({"level" => 0}.to_msgpack)
    msgpack.level.should eq(MessagePackWithEnum::Level::Debug)
    msgpack = MessagePackWithEnum.from_msgpack({"level" => "Info"}.to_msgpack)
    msgpack.level.should eq(MessagePackWithEnum::Level::Info)
  end

  describe "unions" do
    it "parses msgpack with union" do
      msgpack = MessagePackWithUnion.from_msgpack({"string_or_int" => 0}.to_msgpack)
      msgpack.string_or_int.should eq(0)

      msgpack = MessagePackWithUnion.from_msgpack({"string_or_int" => "string"}.to_msgpack)
      msgpack.string_or_int.should eq("string")
    end

    it "parses msgpack with union of custom primitives" do
      bool = MessagePackWithBool.from_msgpack({value: true}.to_msgpack)
      msgpack = MessagePackWithCustomUnion.from_msgpack({"custom" => bool}.to_msgpack)
      msgpack.custom.value.should eq true

      time = MessagePackWithTime.from_msgpack({value: "2014-10-31 23:37:16"}.to_msgpack)
      msgpack = MessagePackWithCustomUnion.from_msgpack({"custom" => time}.to_msgpack)
      msgpack.custom.value.should be_a Time
      msgpack.custom.value.to_s.should eq "2014-10-31 23:37:16 UTC"
    end

    it "parses msgpack with unions" do
      msgpack = MessagePackWithUnions.from_msgpack(({} of String => String).to_msgpack)
      msgpack.a.should eq nil
      msgpack.b.should eq nil
      msgpack.c.should eq nil
      msgpack.d.should eq nil
    end

    it "parse a" do
      msgpack = MessagePackWithUnions.from_msgpack({"a" => "bla"}.to_msgpack)
      msgpack.a.should eq "bla"

      expect_raises(MessagePack::TypeCastError) do
        MessagePackWithUnions.from_msgpack({"a" => [1, 2, 3]}.to_msgpack)
      end
    end

    it "parse b" do
      msgpack = MessagePackWithUnions.from_msgpack({"b" => [1, 2, 3]}.to_msgpack)
      msgpack.b.should eq [1, 2, 3]

      msgpack = MessagePackWithUnions.from_msgpack({"b" => %w(1 2 3)}.to_msgpack)
      msgpack.b.should eq %w(1 2 3)

      expect_raises(MessagePack::TypeCastError) do
        MessagePackWithUnions.from_msgpack({"b" => 1}.to_msgpack)
      end
    end

    it "parse c" do
      msgpack = MessagePackWithUnions.from_msgpack({"c" => [1, 2, 3]}.to_msgpack)
      msgpack.c.should eq [1, 2, 3]

      h = {"bla" => "1"}
      msgpack = MessagePackWithUnions.from_msgpack({"c" => h}.to_msgpack)
      msgpack.c.should eq h

      expect_raises(MessagePack::TypeCastError) do
        MessagePackWithUnions.from_msgpack({"c" => 1}.to_msgpack)
      end
    end

    it "parse d coord" do
      coord = MessagePackCoordinate.new(1.0, 2.0, 3.0)
      msgpack = MessagePackWithUnions.from_msgpack({"d" => coord}.to_msgpack)
      msgpack.d.should eq coord
    end

    it "parse d coordinates" do
      coord = MessagePackCoordinate.new(1.0, 2.0, 3.0)
      msgpack = MessagePackWithUnions.from_msgpack({"d" => {"coordinates" => [coord, coord]}}.to_msgpack)
      msgpack.d.as(MessagePackCoordinates).coordinates.should eq [coord, coord]
    end

    it "parse d unknown struct" do
      expect_raises(MessagePack::TypeCastError) do
        MessagePackWithUnions.from_msgpack({"d" => {"bla" => [1, 2, 3]}}.to_msgpack)
      end
    end

    context "union with nil" do
      it "int" do
        m = MessagePackWithNilUnion.from_msgpack({"int_or_nil" => 1}.to_msgpack)
        m.int_or_nil.should eq 1
      end

      it "hash with nil" do
        m = MessagePackWithNilUnion.from_msgpack({"int_or_nil" => nil}.to_msgpack)
        m.int_or_nil.should eq nil
      end

      it "empty hash" do
        m = MessagePackWithNilUnion.from_msgpack(({} of String => Int32).to_msgpack)
        m.int_or_nil.should eq nil
      end
    end
  end

  describe "(binary support)" do
    binary_data = Bytes.new(UInt8[0x08, 0xE7].to_unsafe, 2)
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
      expect_raises MessagePack::TypeCastError, "Unknown msgpack attribute: foo" do
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

  context "emit_nulls = false" do
    it "work" do
      e = EmitNullsFalse.from_msgpack({"a" => "1"}.to_msgpack)
      e.to_msgpack.should eq Bytes[129, 161, 97, 161, 49]
    end

    it "work" do
      e = EmitNullsFalse.from_msgpack({"a" => "1", "c" => 2}.to_msgpack)
      e.to_msgpack.should eq Bytes[130, 161, 97, 161, 49, 161, 99, 2]
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

  context "unpack to table class" do
    it "works" do
      m = {"name" => "bar", "attributes" => {"foo" => "bar"}}.to_msgpack
      u = UseTableClass.from_msgpack(m)
      u.attributes["foo"].should eq "bar"
    end
  end
end
