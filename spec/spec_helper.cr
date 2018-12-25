require "spec"
require "../src/message_pack"

def as_slice(arr : Array(UInt8))
  Bytes.new(arr.to_unsafe, arr.size)
end

def it_packs_method(value, bytes)
  packer = MessagePack::Packer.new
  result = packer.write(value)
  result.bytes.should eq(bytes)
end

def it_unpacks_method(value, bytes)
  packer = MessagePack::IOUnpacker.new(bytes)
  result = packer.read
  result.should eq(value)
end

macro it_packs(value, bytes, unpack_value = nil, file = __FILE__, line = __LINE__)
  it "serializes #{{{value.stringify}}} to #{{{bytes}}}", {{file}}, {{line}} do
    it_packs_method(({{value}}), {{bytes}})
    it_unpacks_method(({{unpack_value}} || {{value}}), {{bytes}})
  end
end

class ExtClass
  getter a, b

  TYPE_ID = 25_i8

  def initialize(@a : Int32, @b : String)
  end

  def self.new(pull : MessagePack::Unpacker)
    case token = pull.current_token
    when MessagePack::Token::ExtT
      if token.type_id == TYPE_ID
        pull.finish_token!
        io = IO::Memory.new(token.bytes)
        a = io.read_bytes(Int32, IO::ByteFormat::BigEndian)

        size = token.size - 4
        b = String.new(size) do |buffer|
          io.read_fully(Slice.new(buffer, size))
          {size, 0}
        end

        self.new(a, b)
      else
        raise MessagePack::TypeCastError.new("Unknown type_id #{token.type_id}, expected #{TYPE_ID}")
      end
    else
      pull.unexpected_token(token, "Ext")
    end
  end

  def to_msgpack(packer : MessagePack::Packer)
    io = IO::Memory.new
    io.write_bytes(@a, IO::ByteFormat::BigEndian)
    io.write(@b.to_slice)
    packer.write_ext(TYPE_ID, io.to_slice)
  end
end
