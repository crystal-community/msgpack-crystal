require "../src/message_pack"

# Example how to use msgpack ext types specification

class MyExtClass
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

ext = MyExtClass.new(1, "bla")
p ext.to_msgpack # => Bytes[199, 7, 25, 0, 0, 0, 1, 98, 108, 97]

ext = MyExtClass.from_msgpack(Bytes[199, 7, 25, 0, 0, 0, 1, 98, 108, 97])
p ext # => #<MyExtClass:0x1049b1ea0 @a=1, @b="bla">
