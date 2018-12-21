require "./spec_helper"

enum BrokenEnum
  Bla1
  Bla2
end

class BrokenMapping
  MessagePack.mapping({
    a: Int32,
    b: String,
    c: Float64,
  })
end

class BrokenSerializable
  include MessagePack::Serializable

  property a : Int32
  property b : String
  property c : Float64
end

class BrokenSerializableComplex
  include MessagePack::Serializable

  property a : Int32
  property b : String
  property c : Array(Int32)
  property d : Float64
end

describe "broken streaming" do
  {
    {1.5, Int32, true},
    {"bla".to_slice, Float64, true},
    {"bla", Int32, true},
    {1, String, true},
    {nil, Int32, true},
    {true, Int32, true},
    { {1, 2, 3.5, 4, 5}, Array(Int32), true },
    {([] of Int32), Array(Int32), false},
    {[1, 2, 3.5, 4, 5], Array(Int32), true},
    {[1, 2, 3.5, 4, 5], Set(Int32), true},
    {[1, 2, 3.5, 4, 5], Int32, true},
    {({} of String => Int32), Hash(String, Int32), false},
    { {"1" => 2, 2 => 3}, Hash(String, Int32), true },
    { {"1" => 2, "2" => 3}, Hash(String, Int32), false },
    { {"1" => 2, "2" => "3", "4" => 5}, Hash(String, Int32), true },
    { {1, 2, 3.5, 4, 5}, Tuple(Int32, Int32, Int32, Int32, Int32), true },
    { {1, 2, 3.5, 4, 5}, Tuple(Int32, Int32, Int32, Int32), true },
    { {1, 2, 3.5, 4}, Tuple(Int32, Int32, Int32, Int32, Int32), true },
    { {1, 2, 3, 4, 5}, Tuple(Int32, Int32, Int32, Int32), false },    # incorrect size
    { {1, 2, 3, 4}, Tuple(Int32, Int32, Int32, Int32, Int32), true }, # incorrect size
    { {"a" => 1, 2 => "2"}, NamedTuple(a: Int32, bla: String), true },
    { {"a" => 1, "fen" => 1}, NamedTuple(a: Int32, fen: String), true },
    { {"a" => 1, "go" => "2"}, NamedTuple(a: Int32, go: Int32), true },
    {1.5, BrokenEnum, true},
    {1, String | Array(Int32), true},
    { {"a" => 1, "b" => 2, "c" => 3}, BrokenMapping, true },
    { {"a" => 1, "b" => 2, "c" => 3}, BrokenSerializable, true },
    { {"a" => 1, "b" => "2", "c" => [1, 2, 3, 4.5, 6], "d" => 1.1}, BrokenSerializableComplex, true },
  }.each do |(value, type, raises)|
    it "value: #{value.inspect}, load type: #{type.inspect}" do
      packer = MessagePack::Packer.new
      packer.write(value)
      packer.write("k")

      pull = MessagePack::IOUnpacker.new(packer.to_slice)
      unpacker = MessagePack::NodeUnpacker.new(pull.read_node)

      if raises
        expect_raises(MessagePack::TypeCastError) do
          type.new(unpacker)
        end
      else
        type.new(unpacker)
      end

      String.new(pull).should eq "k"
    end
  end
end
