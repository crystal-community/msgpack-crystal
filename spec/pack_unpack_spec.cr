# coding: utf-8
require "./spec_helper"

describe "pack and unpack integration specs" do
  it "write hash" do
    data = {"bla" => 11.5}
    packer = MessagePack::Packer.new
    packer.write(data)
    unpack = MessagePack::IOUnpacker.new(packer.to_slice)
    unpack.read_hash.should eq data
  end

  it "write hash by parts" do
    packer = MessagePack::Packer.new
    packer.write_hash_start(2)
    packer.write("key1")
    packer.write(11.5)
    packer.write("key2")
    packer.write(true)
    unpack = MessagePack::IOUnpacker.new(packer.to_slice)
    unpack.read_hash.should eq({"key1" => 11.5, "key2" => true})
  end

  it "write array" do
    data = ["bla", 11.5]
    packer = MessagePack::Packer.new
    packer.write(data)
    unpack = MessagePack::IOUnpacker.new(packer.to_slice)
    unpack.read_array.should eq data
  end

  it "write array by parts" do
    packer = MessagePack::Packer.new
    packer.write_array_start(4)
    packer.write("key1")
    packer.write(11.5)
    packer.write("key2")
    packer.write(true)
    unpack = MessagePack::IOUnpacker.new(packer.to_slice)
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
    unpack = MessagePack::IOUnpacker.new(packer.to_slice)
    unpack.read_hash.should eq({"key1" => 11.5, "key2" => [true, "value", 38]})
  end

  it "works with unicode strings" do
    str = "⬠ ⬡ ⬢ ⬣ ⬤ ⬥ ⬦"
    packer = MessagePack::Packer.new
    packer.write(str)
    unpack = MessagePack::IOUnpacker.new(packer.to_slice)
    unpack.read_string.should eq str
  end

  it "works with binary (invalid byte sequence for UTF-8)" do
    bytes = Bytes[0x08, 0xe7]
    packer = MessagePack::Packer.new
    packer.write(bytes)
    unpack = MessagePack::IOUnpacker.new(packer.to_slice)
    unpack.read_string.should eq String.new(bytes)
  end

  it "tuples" do
    tuple = {1, true, "false", 1.5}
    packer = MessagePack::Packer.new
    packer.write(tuple)
    unpack = MessagePack::IOUnpacker.new(packer.to_slice)
    unpack.read_array.should eq([1, true, "false", 1.5])
  end

  it "symbol" do
    val = :bla
    packer = MessagePack::Packer.new
    packer.write(val)
    unpack = MessagePack::IOUnpacker.new(packer.to_slice)
    unpack.read_string.should eq "bla"
  end

  context "ext" do
    [1, 2, 4, 8, 16, 25, 259, UInt16::MAX.to_i32 + 5].each do |length|
      it "work with #{length}" do
        packer = MessagePack::Packer.new
        b = Bytes.new(length) { |i| (i % 256).to_u8 }
        packer.write_ext(1_i8, b)
        msgpack = packer.to_slice

        unpacker = MessagePack::IOUnpacker.new(msgpack)
        token = unpacker.current_token

        case token
        when MessagePack::Token::ExtT
          token.type_id.should eq 1_i8
          token.size.should eq length.to_u32
          token.bytes.each_with_index do |v, i|
            v.should eq (i % 256).to_u8
          end
        else
          raise "unknown token #{token.inspect}"
        end
      end
    end
  end
end
