require "./spec_helper"
require "json"

record MessagePackAttrPoint, x : Int32, y : Int32 do
  include MessagePack::Serializable
end

class MessagePackAttrEmptyClass
  include MessagePack::Serializable

  def initialize
  end
end

class MessagePackAttrEmptyClassUnmapped
  include MessagePack::Serializable
  include MessagePack::Serializable::Unmapped
end

class MessagePackAttrPerson
  include MessagePack::Serializable

  property name : String
  property age : Int32?

  def_equals name, age

  def initialize(@name : String)
  end
end

class MessagePackAttrPersonStrict
  include MessagePack::Serializable
  include MessagePack::Serializable::Strict

  property name : String
  property age : Int32?
end

class MessagePackAttrPersonExtra
  include MessagePack::Serializable
  include MessagePack::Serializable::Unmapped

  property name : String
  property age : Int32?
end

class NumbersMessagePackAttr
  include MessagePack::Serializable

  property int8 : Int8
  property int16 : Int16
  property int32 : Int32
  property int64 : Int64
  property uint8 : Int8
  property uint16 : Int16
  property uint32 : Int32
  property uint64 : Int64
end

class MessagePackAttrWithBool
  include MessagePack::Serializable
  property value : Bool
end

class MessagePackAttrPersonEmittingNull
  include MessagePack::Serializable

  property name : String
  @[MessagePack::Field(emit_null: true)]
  property age : Int32?
end

@[MessagePack::Serializable::Options(emit_nulls: true)]
class MessagePackAttrPersonEmittingNullsByOptions
  include MessagePack::Serializable

  property name : String
  property age : Int32?
  property value1 : Int32?

  @[MessagePack::Field(emit_null: false)]
  property value2 : Int32?
end

class MessagePackAttrWithTime
  include MessagePack::Serializable

  @[MessagePack::Field(converter: Time::Format.new("%F %T"))]
  property value : Time
end

class MessagePackAttrWithNilableTime
  include MessagePack::Serializable

  @[MessagePack::Field(converter: Time::Format.new("%F %T"))]
  property value : Time?

  def initialize
  end
end

class MessagePackAttrWithNilableTimeEmittingNull
  include MessagePack::Serializable

  @[MessagePack::Field(converter: Time::Format.new("%F %T"), emit_null: true)]
  property value : Time?

  def initialize
  end
end

class MessagePackAttrWithPropertiesKey
  include MessagePack::Serializable

  property properties : Hash(String, String)
end

class MessagePackAttrWithKeywordsMapping
  include MessagePack::Serializable

  property end : Int32
  property abstract : Int32
end

class MessagePackAttrWithProblematicKeys
  include MessagePack::Serializable

  property key : Int32
  property pull : Int32
end

class MessagePackAttrWithSet
  include MessagePack::Serializable

  property set : Set(String)
end

class MessagePackAttrWithUnion
  include MessagePack::Serializable
  property string_or_int : Union(Int32, String)
end

class MessagePackAttrWithNilUnion
  include MessagePack::Serializable
  property int_or_nil : Int32?
end

class MessagePackAttrWithCustomUnion
  include MessagePack::Serializable
  property custom : Union(MessagePackAttrWithTime, MessagePackAttrWithBool)
end

class MessagePackAttrWithUnions
  include MessagePack::Serializable
  property a : Union(String, Int32, Nil)
  property b : Union(Array(Int32), Array(String), Nil)
  property c : Union(Array(Int32), Hash(String, String), Nil)
  property d : Union(MessagePackAttrCoordinate, MessagePackAttrCoordinates, Nil)
end

class MessagePackAttrWithEnum
  include MessagePack::Serializable
  enum Level
    Debug = 0
    Info  = 1
  end
  property level : Level
end

struct MessagePackAttrCoordinate
  include MessagePack::Serializable
  property x : Float64
  property y : Float64
  property z : Float64

  def initialize(@x : Float64, @y : Float64, @z : Float64)
  end
end

class MessagePackAttrCoordinates
  include MessagePack::Serializable
  property coordinates : Array(MessagePackAttrCoordinate)
end

class MessagePackAttrKVS
  include MessagePack::Serializable
  property key : String
  property val : Bytes?
end

class StrictMessagePackAttrKVS
  include MessagePack::Serializable
  include MessagePack::Serializable::Strict
  property key : String
  property val : Bytes?
end

class AttrEmitNullsFalse
  include MessagePack::Serializable
  property a : String
  property b : String?
  property c : Int32?
end

class MessagePackAttrWithDefaults
  include MessagePack::Serializable

  property a = 11
  property b = "Haha"
  property c = true
  property d = false
  property e : Bool? = false
  property f : Int32? = 1
  property g : Int32?
  property h = [1, 2, 3]
end

class AttrUseTableClass
  include MessagePack::Serializable
  property name : String
  property attributes : MessagePack::Table
end

class MessagePackAttrWithSmallIntegers
  include MessagePack::Serializable

  property foo : Int16
  property bar : Int8
end

class MessagePackAttrWithNilableUnion
  include MessagePack::Serializable

  property value : Int32?
end

class MessagePackAttrWithNilableUnion2
  include MessagePack::Serializable

  property value : Int32 | Nil
end

class MessagePackAttrWithPresence
  include MessagePack::Serializable
  include MessagePack::Serializable::Presence

  property first_name : String?
  property last_name : String?
end

class MessagePackAttrWithQueryAttributes
  include MessagePack::Serializable
  include MessagePack::Serializable::Presence

  property? foo : Bool

  @[MessagePack::Field(key: "is_bar")]
  property? bar : Bool = false
end

module MessagePackAttrModule
  property moo : Int32 = 10
end

class MessagePackAttrModuleTest
  include MessagePackAttrModule
  include MessagePack::Serializable

  @[MessagePack::Field(key: "phoo")]
  property foo = 15

  def initialize; end

  def to_tuple
    {@moo, @foo}
  end
end

class MessagePackAttrModuleTest2 < MessagePackAttrModuleTest
  property bar : Int32

  def initialize(@bar : Int32); end

  def to_tuple
    {@moo, @foo, @bar}
  end
end

struct MessagePackAttrPersonWithJSON
  include MessagePack::Serializable
  include JSON::Serializable

  property name : String
  property age : Int32?

  def initialize(@name : String, @age : Int32? = nil)
  end
end

struct MessagePackAttrPersonWithJSONInitializeHook
  include JSON::Serializable
  include MessagePack::Serializable

  property name : String
  property age : Int32?

  def initialize(@name : String, @age : Int32? = nil)
    after_initialize
  end

  @[MessagePack::Field(ignore: true)]
  @[JSON::Field(ignore: true)]
  property msg : String?

  def after_initialize
    @msg = "Hello " + name
  end
end

module Discriminator
  abstract struct Message
    include MessagePack::Serializable

    use_msgpack_discriminator "type", {
      created: Created,
      updated: Updated,
    }

    getter id : Int32
  end

  struct Created < Message
    getter created_at : Time
  end

  struct Updated < Message
    getter updated_at : Time
  end
end

describe "MessagePack mapping" do
  it "works with record" do
    MessagePackAttrPoint.new(1, 2).to_msgpack.should eq Bytes[130, 161, 120, 1, 161, 121, 2]
    MessagePackAttrPoint.from_msgpack(Bytes[130, 161, 120, 1, 161, 121, 2]).should eq MessagePackAttrPoint.new(1, 2)
  end

  it "empty class" do
    e = MessagePackAttrEmptyClass.new
    e.to_msgpack.should eq Bytes[128]
    MessagePackAttrEmptyClass.from_msgpack(Bytes[128])
  end

  it "empty class with unmapped" do
    MessagePackAttrEmptyClassUnmapped.from_msgpack(Bytes[130, 161, 120, 1, 161, 121, 2]).msgpack_unmapped.should eq({"x" => 1_u8, "y" => 2_u8})
  end

  it "parses person" do
    person = MessagePackAttrPerson.from_msgpack({"name" => "John", "age" => 30}.to_msgpack)
    person.should be_a(MessagePackAttrPerson)
    person.name.should eq("John")
    person.age.should eq(30)
  end

  it "parses person without age" do
    person = MessagePackAttrPerson.from_msgpack({"name": "John"}.to_msgpack)
    person.should be_a(MessagePackAttrPerson)
    person.name.should eq("John")
    person.name.size.should eq(4) # This verifies that name is not nilable
    person.age.should be_nil
  end

  it "parses array of people" do
    people = Array(MessagePackAttrPerson).from_msgpack([{"name" => "John"}, {"name" => "Doe"}].to_msgpack)
    people.size.should eq(2)
  end

  it "does to_msgpack" do
    person = MessagePackAttrPerson.from_msgpack({"name" => "John", "age" => 30}.to_msgpack)
    person2 = MessagePackAttrPerson.from_msgpack(person.to_msgpack)
    person2.should eq(person)
  end

  it "does from_msgpack with all ints" do
    numbers = NumbersMessagePackAttr.from_msgpack({
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
    person = MessagePackAttrPerson.from_msgpack({"name" => "John", "age" => 30, "foo" => "bar"}.to_msgpack)
    person.should be_a(MessagePackAttrPerson)
    person.name.should eq("John")
    person.age.should eq(30)
  end

  it "parses strict person with unknown attributes" do
    expect_raises MessagePack::TypeCastError, "Unknown msgpack attribute: foo" do
      MessagePackAttrPersonStrict.from_msgpack({"name" => "John", "age" => 30, "foo" => "bar"}.to_msgpack)
    end
  end

  it "should parse extra fields (MessagePackAttrPersonExtra with on_unknown_msgpack_attribute)" do
    person = MessagePackAttrPersonExtra.from_msgpack({"name" => "John", "age" => 30, "x" => "1", "y" => 2, "z" => [1, 2, 3]}.to_msgpack)
    person.name.should eq("John")
    person.age.should eq(30)
    person.msgpack_unmapped.should eq({"x" => "1", "y" => 2_i64, "z" => [1, 2, 3]})
  end

  it "should to store extra fields (MessagePackAttrPersonExtra with on_to_msgpack)" do
    person = MessagePackAttrPersonExtra.from_msgpack({"name" => "John", "age" => 30, "x" => "1", "y" => 2, "z" => [1, 2, 3]}.to_msgpack)
    person.name = "John1"
    person.msgpack_unmapped.delete("y")
    person.msgpack_unmapped["q"] = "w"
    res = person.to_msgpack
    MessagePack::IOUnpacker.new(res).read.should eq({"name" => "John1", "age" => 30_u8, "x" => "1", "z" => [1_u8, 2_u8, 3_u8], "q" => "w"})
  end

  it "raises if non-nilable attribute is nil" do
    expect_raises MessagePack::TypeCastError, "Missing msgpack attribute: name" do
      MessagePackAttrPerson.from_msgpack({"age" => 30}.to_msgpack)
    end
  end

  it "raises if not an object" do
    expect_raises MessagePack::TypeCastError, "Unexpected token StringT(\"1234566789...\") expected HashT at 0" do
      MessagePackAttrPerson.from_msgpack("1234566789abcd".to_msgpack)
    end
  end

  it "raises if data type does not match" do
    expect_raises MessagePack::TypeCastError, "Couldn't parse data as {Int32, Nil} at 15" do
      MessagePackAttrPerson.from_msgpack({"name" => "John", "age" => "30"}.to_msgpack)
    end
  end

  it "doesn't emits null when doing to_msgpack" do
    person = MessagePackAttrPerson.from_msgpack({"name" => "John"}.to_msgpack)
    person.to_msgpack.should eq({"name" => "John"}.to_msgpack)
  end

  it "emits null on request when doing to_msgpack" do
    person = MessagePackAttrPersonEmittingNull.from_msgpack({"name" => "John"}.to_msgpack)
    person.to_msgpack.should eq({"name" => "John", "age" => nil}.to_msgpack)
  end

  it "emit_nulls option" do
    person = MessagePackAttrPersonEmittingNullsByOptions.from_msgpack({"name" => "John"}.to_msgpack)
    person.to_msgpack.should eq({"name" => "John", "age" => nil, "value1" => nil}.to_msgpack)
  end

  it "doesn't raises on false value when not-nil" do
    msgpack = MessagePackAttrWithBool.from_msgpack({"value" => false}.to_msgpack)
    msgpack.value.should be_false
  end

  it "parses msgpack with Time::Format converter" do
    msg = {"value" => "2018-05-12 02:07:34"}.to_msgpack
    msgpack = MessagePackAttrWithTime.from_msgpack(msg)
    msgpack.value.should be_a(Time)
    msgpack.value.to_s.should eq("2018-05-12 02:07:34 UTC")
    msgpack.to_msgpack.should eq(msg)
  end

  it "allows setting a nilable property to nil" do
    person = MessagePackAttrPerson.new("John")
    person.age = 1
    person.age = nil
  end

  it "parses simple mapping" do
    person = MessagePackAttrPerson.from_msgpack({"name" => "John", "age" => 30}.to_msgpack)
    person.should be_a(MessagePackAttrPerson)
    person.name.should eq("John")
    person.age.should eq(30)
  end

  it "parses simple mapping, key is binary" do
    person = MessagePackAttrPerson.from_msgpack({"name".to_slice => "John", "age".to_slice => 30}.to_msgpack)
    person.should be_a(MessagePackAttrPerson)
    person.name.should eq("John")
    person.age.should eq(30)
  end

  it "outputs with converter when nilable" do
    msgpack = MessagePackAttrWithNilableTime.new
    msgpack.to_msgpack.should eq(Bytes[128])
  end

  it "outputs with converter when nilable" do
    msgpack = MessagePackAttrWithNilableTimeEmittingNull.new
    msgpack.to_msgpack.should eq(Bytes[129, 165, 118, 97, 108, 117, 101, 192])
  end

  it "parses msgpack with keywords" do
    msgpack = MessagePackAttrWithKeywordsMapping.from_msgpack({"end" => 1, "abstract" => 2}.to_msgpack)
    msgpack.end.should eq(1)
    msgpack.abstract.should eq(2)
  end

  it "parses msgpack with problematic keys" do
    msgpack = MessagePackAttrWithProblematicKeys.from_msgpack({"key" => 1, "pull" => 2}.to_msgpack)
    msgpack.key.should eq(1)
    msgpack.pull.should eq(2)
  end

  it "outputs MessagePack with properties key" do
    input = {
      properties: {"foo" => "bar"},
    }.to_msgpack
    msgpack = MessagePackAttrWithPropertiesKey.from_msgpack(input)
    msgpack.to_msgpack.should eq(input)
  end

  it "parses msgpack array as set" do
    msgpack = MessagePackAttrWithSet.from_msgpack({set: ["a", "b", "a"]}.to_msgpack)
    msgpack.set.should eq(Set(String){"a", "b"})
  end

  it "parses msgpack with enum" do
    msgpack = MessagePackAttrWithEnum.from_msgpack({"level" => 0}.to_msgpack)
    msgpack.level.should eq(MessagePackAttrWithEnum::Level::Debug)
    msgpack = MessagePackAttrWithEnum.from_msgpack({"level" => "Info"}.to_msgpack)
    msgpack.level.should eq(MessagePackAttrWithEnum::Level::Info)
  end

  describe "unions" do
    it "parses msgpack with union" do
      msgpack = MessagePackAttrWithUnion.from_msgpack({"string_or_int" => 0}.to_msgpack)
      msgpack.string_or_int.should eq(0)

      msgpack = MessagePackAttrWithUnion.from_msgpack({"string_or_int" => "string"}.to_msgpack)
      msgpack.string_or_int.should eq("string")
    end

    it "parses msgpack with union of custom primitives" do
      bool = MessagePackAttrWithBool.from_msgpack({value: true}.to_msgpack)
      msgpack = MessagePackAttrWithCustomUnion.from_msgpack({"custom" => bool}.to_msgpack)
      msgpack.custom.value.should eq true

      time = MessagePackAttrWithTime.from_msgpack({value: "2018-05-12 02:07:34"}.to_msgpack)
      msgpack = MessagePackAttrWithCustomUnion.from_msgpack({"custom" => time}.to_msgpack)
      msgpack.custom.value.should be_a Time
      msgpack.custom.value.to_s.should eq "2018-05-12 02:07:34 UTC"
    end

    it "parses msgpack with unions" do
      msgpack = MessagePackAttrWithUnions.from_msgpack(({} of String => String).to_msgpack)
      msgpack.a.should eq nil
      msgpack.b.should eq nil
      msgpack.c.should eq nil
      msgpack.d.should eq nil
    end

    it "parse a" do
      msgpack = MessagePackAttrWithUnions.from_msgpack({"a" => "bla"}.to_msgpack)
      msgpack.a.should eq "bla"

      expect_raises(MessagePack::TypeCastError) do
        MessagePackAttrWithUnions.from_msgpack({"a" => [1, 2, 3]}.to_msgpack)
      end
    end

    it "parse b" do
      msgpack = MessagePackAttrWithUnions.from_msgpack({"b" => [1, 2, 3]}.to_msgpack)
      msgpack.b.should eq [1, 2, 3]

      msgpack = MessagePackAttrWithUnions.from_msgpack({"b" => ["1", "2", "3"]}.to_msgpack)
      msgpack.b.should eq ["1", "2", "3"]

      expect_raises(MessagePack::TypeCastError) do
        MessagePackAttrWithUnions.from_msgpack({"b" => 1}.to_msgpack)
      end
    end

    it "parse c" do
      msgpack = MessagePackAttrWithUnions.from_msgpack({"c" => [1, 2, 3]}.to_msgpack)
      msgpack.c.should eq [1, 2, 3]

      h = {"bla" => "1"}
      msgpack = MessagePackAttrWithUnions.from_msgpack({"c" => h}.to_msgpack)
      msgpack.c.should eq h

      expect_raises(MessagePack::TypeCastError) do
        MessagePackAttrWithUnions.from_msgpack({"c" => 1}.to_msgpack)
      end
    end

    it "parse d coord" do
      coord = MessagePackAttrCoordinate.new(1.0, 2.0, 3.0)
      msgpack = MessagePackAttrWithUnions.from_msgpack({"d" => coord}.to_msgpack)
      msgpack.d.should eq coord
    end

    it "parse d coordinates" do
      coord = MessagePackAttrCoordinate.new(1.0, 2.0, 3.0)
      msgpack = MessagePackAttrWithUnions.from_msgpack({"d" => {"coordinates" => [coord, coord]}}.to_msgpack)
      msgpack.d.as(MessagePackAttrCoordinates).coordinates.should eq [coord, coord]
    end

    it "parse d unknown struct" do
      expect_raises(MessagePack::TypeCastError) do
        MessagePackAttrWithUnions.from_msgpack({"d" => {"bla" => [1, 2, 3]}}.to_msgpack)
      end
    end

    context "union with nil" do
      it "int" do
        m = MessagePackAttrWithNilUnion.from_msgpack({"int_or_nil" => 1}.to_msgpack)
        m.int_or_nil.should eq 1
      end

      it "hash with nil" do
        m = MessagePackAttrWithNilUnion.from_msgpack({"int_or_nil" => nil}.to_msgpack)
        m.int_or_nil.should eq nil
      end

      it "empty hash" do
        m = MessagePackAttrWithNilUnion.from_msgpack(({} of String => Int32).to_msgpack)
        m.int_or_nil.should eq nil
      end
    end
  end

  {false, true}.each do |zero_copy|
    describe "(binary support)" do
      binary_data = Bytes.new(UInt8[0x08, 0xE7].to_unsafe, 2)
      it "parses binary data" do
        kvs = MessagePackAttrKVS.from_msgpack({"key" => "a", "val" => binary_data}.to_msgpack, zero_copy: zero_copy)
        kvs.should be_a(MessagePackAttrKVS)
        kvs.key.should eq("a")
        kvs.val.should eq(binary_data)
      end

      it "parses binary data with unknown attributes" do
        kvs = MessagePackAttrKVS.from_msgpack({"key" => "a", "val" => binary_data, "foo" => "bar"}.to_msgpack, zero_copy: zero_copy)
        kvs.should be_a(MessagePackAttrKVS)
        kvs.key.should eq("a")
        kvs.val.should eq(binary_data)
      end

      it "parses binary data without attributes" do
        kvs = MessagePackAttrKVS.from_msgpack({"key" => "a"}.to_msgpack, zero_copy: zero_copy)
        kvs.should be_a(MessagePackAttrKVS)
        kvs.key.should eq("a")
        kvs.val.should eq(nil)
      end

      it "parses binary data with nil value" do
        kvs = MessagePackAttrKVS.from_msgpack({"key" => "a", "val" => nil}.to_msgpack, zero_copy: zero_copy)
        kvs.should be_a(MessagePackAttrKVS)
        kvs.key.should eq("a")
        kvs.val.should eq(nil)
      end

      it "parses strict binary data" do
        kvs = StrictMessagePackAttrKVS.from_msgpack({"key" => "a", "val" => binary_data}.to_msgpack, zero_copy: zero_copy)
        kvs.should be_a(StrictMessagePackAttrKVS)
        kvs.key.should eq("a")
        kvs.val.should eq(binary_data)
      end

      it "parses strict binary data with unknown attributes" do
        expect_raises MessagePack::TypeCastError, "Unknown msgpack attribute: foo" do
          StrictMessagePackAttrKVS.from_msgpack({"key" => "a", "val" => binary_data, "foo" => "bar"}.to_msgpack, zero_copy: zero_copy)
        end
      end

      it "parses strict binary data without attributes" do
        kvs = StrictMessagePackAttrKVS.from_msgpack({"key" => "a"}.to_msgpack, zero_copy: zero_copy)
        kvs.should be_a(StrictMessagePackAttrKVS)
        kvs.key.should eq("a")
        kvs.val.should eq(nil)
      end

      it "parses strict binary data with nil value" do
        kvs = StrictMessagePackAttrKVS.from_msgpack({"key" => "a", "val" => nil}.to_msgpack, zero_copy: zero_copy)
        kvs.should be_a(StrictMessagePackAttrKVS)
        kvs.key.should eq("a")
        kvs.val.should eq(nil)
      end
    end
  end

  context "emit_nulls = false" do
    it "work" do
      e = AttrEmitNullsFalse.from_msgpack({"a" => "1"}.to_msgpack)
      e.to_msgpack.should eq Bytes[129, 161, 97, 161, 49]
    end

    it "work" do
      e = AttrEmitNullsFalse.from_msgpack({"a" => "1", "c" => 2}.to_msgpack)
      e.to_msgpack.should eq Bytes[130, 161, 97, 161, 49, 161, 99, 2]
    end
  end

  describe "parses msgpack with defaults" do
    it "pack unpack" do
      msg = {"a" => 1, "b" => "bla"}.to_msgpack
      obj = MessagePackAttrWithDefaults.from_msgpack(msg)
      obj.a.should eq 1
      obj.c.should eq true
      msg2 = obj.to_msgpack
      msg.should_not eq msg2

      obj = MessagePackAttrWithDefaults.from_msgpack(msg2)
      obj.a.should eq 1
      obj.c.should eq true
    end

    it "mixed" do
      msgpack = MessagePackAttrWithDefaults.from_msgpack({"a" => 1, "b" => "bla"}.to_msgpack)
      msgpack.a.should eq 1
      msgpack.b.should eq "bla"

      msgpack = MessagePackAttrWithDefaults.from_msgpack({"a" => 1}.to_msgpack)
      msgpack.a.should eq 1
      msgpack.b.should eq "Haha"

      msgpack = MessagePackAttrWithDefaults.from_msgpack({"b" => "bla"}.to_msgpack)
      msgpack.a.should eq 11
      msgpack.b.should eq "bla"

      msgpack = MessagePackAttrWithDefaults.from_msgpack(({} of String => String).to_msgpack)
      msgpack.a.should eq 11
      msgpack.b.should eq "Haha"

      msgpack = MessagePackAttrWithDefaults.from_msgpack({"a" => nil, "b" => nil}.to_msgpack)
      msgpack.a.should eq 11
      msgpack.b.should eq "Haha"
    end

    it "bool" do
      msgpack = MessagePackAttrWithDefaults.from_msgpack(({} of String => String).to_msgpack)
      msgpack.c.should eq true
      typeof(msgpack.c).should eq Bool
      msgpack.d.should eq false
      typeof(msgpack.d).should eq Bool

      msgpack = MessagePackAttrWithDefaults.from_msgpack({"c" => false}.to_msgpack)
      msgpack.c.should eq false
      msgpack = MessagePackAttrWithDefaults.from_msgpack({"c" => true}.to_msgpack)
      msgpack.c.should eq true

      msgpack = MessagePackAttrWithDefaults.from_msgpack({"d" => false}.to_msgpack)
      msgpack.d.should eq false
      msgpack = MessagePackAttrWithDefaults.from_msgpack({"d" => true}.to_msgpack)
      msgpack.d.should eq true
    end

    it "with nilable" do
      msgpack = MessagePackAttrWithDefaults.from_msgpack(({} of String => String).to_msgpack)

      msgpack.e.should eq false
      typeof(msgpack.e).should eq(Bool | Nil)

      msgpack.f.should eq 1
      typeof(msgpack.f).should eq(Int32 | Nil)

      msgpack.g.should eq nil
      typeof(msgpack.g).should eq(Int32 | Nil)

      msgpack = MessagePackAttrWithDefaults.from_msgpack({"e" => false}.to_msgpack)
      msgpack.e.should eq false
      msgpack = MessagePackAttrWithDefaults.from_msgpack({"e" => true}.to_msgpack)
      msgpack.e.should eq true
    end

    it "create new array every time" do
      msgpack = MessagePackAttrWithDefaults.from_msgpack(({} of String => String).to_msgpack)
      msgpack.h.should eq [1, 2, 3]
      msgpack.h << 4
      msgpack.h.should eq [1, 2, 3, 4]

      msgpack = MessagePackAttrWithDefaults.from_msgpack(({} of String => String).to_msgpack)
      msgpack.h.should eq [1, 2, 3]
    end
  end

  it "coordinates" do
    data = Base64.decode("gqtjb29yZGluYXRlc5KFoXjLP9CCVH9IMu6hecs/1TGvKza6XKF6yz/rkkVzHwTxpG5hbWWrd3lzcnF4IDM4NTGkb3B0c4GhMZIBw4WheMs/34Wk1YNbGqF5yz/Wjbls2JVWoXrLP849VOX0i/ikbmFtZatrdnFuenIgMzk0NaRvcHRzgaExkgHDpGluZm+pc29tZSBpbmZv")
    obj = MessagePackAttrCoordinates.from_msgpack(data)
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
      u = AttrUseTableClass.from_msgpack(m)
      u.attributes["foo"].should eq "bar"
    end
  end

  it "allows small types of integer" do
    msgpack = MessagePackAttrWithSmallIntegers.from_msgpack({foo: 23, bar: 7}.to_msgpack)

    msgpack.foo.should eq(23)
    typeof(msgpack.foo).should eq(Int16)

    msgpack.bar.should eq(7)
    typeof(msgpack.bar).should eq(Int8)
  end

  it "parses nilable union" do
    obj = MessagePackAttrWithNilableUnion.from_msgpack({value: 1}.to_msgpack)
    obj.value.should eq(1)
    obj.to_msgpack.should eq({value: 1}.to_msgpack)

    obj = MessagePackAttrWithNilableUnion.from_msgpack({value: nil}.to_msgpack)
    obj.value.should be_nil
    obj.to_msgpack.should eq(Bytes[128])

    obj = MessagePackAttrWithNilableUnion.from_msgpack(Bytes[128])
    obj.value.should be_nil
    obj.to_msgpack.should eq(Bytes[128])
  end

  it "parses nilable union2" do
    obj = MessagePackAttrWithNilableUnion2.from_msgpack({value: 1}.to_msgpack)
    obj.value.should eq(1)
    obj.to_msgpack.should eq({value: 1}.to_msgpack)

    obj = MessagePackAttrWithNilableUnion2.from_msgpack({value: nil}.to_msgpack)
    obj.value.should be_nil
    obj.to_msgpack.should eq(Bytes[128])

    obj = MessagePackAttrWithNilableUnion2.from_msgpack(Bytes[128])
    obj.value.should be_nil
    obj.to_msgpack.should eq(Bytes[128])
  end

  describe "parses MessagePack with presence markers" do
    it "parses person with absent attributes" do
      msgpack = MessagePackAttrWithPresence.from_msgpack({first_name: nil}.to_msgpack)
      msgpack.first_name.should be_nil
      msgpack.key_present?(:"first_name").should be_true
      msgpack.last_name.should be_nil
      msgpack.key_present?(:"last_name").should be_false
    end
  end

  describe "with query attributes" do
    it "defines query getter" do
      msgpack = MessagePackAttrWithQueryAttributes.from_msgpack({foo: true}.to_msgpack)
      msgpack.foo?.should be_true
      msgpack.bar?.should be_false
    end

    it "defines query getter with class restriction" do
      {% begin %}
        {% methods = MessagePackAttrWithQueryAttributes.methods %}
        {{ methods.find(&.name.==("foo?")).return_type }}.should eq(Bool)
        {{ methods.find(&.name.==("bar?")).return_type }}.should eq(Bool)
      {% end %}
    end

    it "defines non-query setter and presence methods" do
      msgpack = MessagePackAttrWithQueryAttributes.from_msgpack({foo: false}.to_msgpack)
      msgpack.key_present?(:"bar").should be_false
      msgpack.bar = true
      msgpack.bar?.should be_true
    end

    it "maps non-query attributes" do
      msgpack = MessagePackAttrWithQueryAttributes.from_msgpack({foo: false, is_bar: false}.to_msgpack)
      msgpack.key_present?(:"bar").should be_true
      msgpack.bar?.should be_false
      msgpack.bar = true
      msgpack.to_msgpack.should eq({foo: false, is_bar: true}.to_msgpack)
    end

    it "raises if non-nilable attribute is nil" do
      error_message = "msg"
      ex = expect_raises MessagePack::TypeCastError, error_message do
        MessagePackAttrWithQueryAttributes.from_msgpack({is_bar: true}.to_msgpack)
      end
    end
  end

  describe "work with module and inheritance" do
    it { MessagePackAttrModuleTest.from_msgpack({phoo: 20}.to_msgpack).to_tuple.should eq({10, 20}) }
    it { MessagePackAttrModuleTest.from_msgpack({phoo: 20}.to_msgpack).to_tuple.should eq({10, 20}) }
    it { MessagePackAttrModuleTest2.from_msgpack({phoo: 20, bar: 30}.to_msgpack).to_tuple.should eq({10, 20, 30}) }
    it { MessagePackAttrModuleTest2.from_msgpack({bar: 30, moo: 40}.to_msgpack).to_tuple.should eq({40, 15, 30}) }
  end

  it "works together with yaml" do
    person = MessagePackAttrPersonWithJSON.new("Vasya", 30)
    person.to_json.should eq "{\"name\":\"Vasya\",\"age\":30}"

    MessagePackAttrPersonWithJSON.from_json(person.to_json).should eq person
    MessagePackAttrPersonWithJSON.from_msgpack(person.to_msgpack).should eq person
  end

  it "yaml and json with after_initialize hook" do
    person = MessagePackAttrPersonWithJSONInitializeHook.new("Vasya", 30)
    person.msg.should eq "Hello Vasya"

    person.to_json.should eq "{\"name\":\"Vasya\",\"age\":30}"

    MessagePackAttrPersonWithJSONInitializeHook.from_json(person.to_json).msg.should eq "Hello Vasya"
    MessagePackAttrPersonWithJSONInitializeHook.from_msgpack(person.to_msgpack).msg.should eq "Hello Vasya"
  end

  it "allows the use of a discriminator field to determine which type to deserialize as" do
    time = Time::Format::RFC_3339.parse("2021-11-14T12:28:32Z")
    created = Discriminator::Message.from_msgpack({type: "created", id: 123, created_at: time}.to_msgpack)
    updated = Discriminator::Message.from_msgpack({type: "updated", id: 123, updated_at: time}.to_msgpack)

    # Ensure object types are as expected.
    created.should be_a Discriminator::Created
    updated.should be_a Discriminator::Updated

    # Ensure type-specific properties were deserialized appropriately. We need to
    # use the .as(Type) here due to the compile-time type being
    # `Disciminator::Message` instead of the more specific types.
    created.as(Discriminator::Created).created_at.should eq time
    updated.as(Discriminator::Updated).updated_at.should eq time
  end
end
