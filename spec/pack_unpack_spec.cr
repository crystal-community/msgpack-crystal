require "./spec_helper"

describe "pack and unpack integration specs" do
  it "write hash" do
    data = {"bla" => 11.5}
    packer = MessagePack::Packer.new
    packer.write(data)
    unpack = MessagePack::Unpacker.new(packer.to_slice)
    unpack.read_hash.should eq data
  end

  it "write hash by parts" do
    packer = MessagePack::Packer.new
    packer.write_hash_start(2)
    packer.write("key1")
    packer.write(11.5)
    packer.write("key2")
    packer.write(true)
    unpack = MessagePack::Unpacker.new(packer.to_slice)
    unpack.read_hash.should eq({"key1" => 11.5, "key2" => true})
  end

  it "write array" do
    data = ["bla", 11.5]
    packer = MessagePack::Packer.new
    packer.write(data)
    unpack = MessagePack::Unpacker.new(packer.to_slice)
    unpack.read_array.should eq data
  end

  it "write array by parts" do
    packer = MessagePack::Packer.new
    packer.write_array_start(4)
    packer.write("key1")
    packer.write(11.5)
    packer.write("key2")
    packer.write(true)
    unpack = MessagePack::Unpacker.new(packer.to_slice)
    unpack.read_array.should eq(["key1", 11.5, "key2", true])
  end

  it "write hash and array by parts" do
    packer = MessagePack::Packer.new
    packer.write_hash_start(2)
    packer.write("key1")
    packer.write(11.5)
    packer.write("key2")
    packer.write_array_start(3)
    packer.write(true)
    packer.write("value")
    packer.write(38)
    unpack = MessagePack::Unpacker.new(packer.to_slice)
    unpack.read_hash.should eq({"key1" => 11.5, "key2" => [true, "value", 38]})
  end
end
