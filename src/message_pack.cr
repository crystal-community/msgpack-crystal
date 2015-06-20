module MessagePack
  # Represents a possible type inside a MessagePack Array or MessagePack Hash (Table)
  alias Type = Nil | Bool |
    Int8  | Int16  | Int32  | Int64  |
    UInt8 | UInt16 | UInt32 | UInt64 |
    Float32 | Float64 | String | Array(Type) | Hash(Type, Type)

  # A MessagePack Table. Just a convenience alias.
  alias Table = Hash(String, Type)

  def self.pack(value : Type)
    Packer.new.write(value).bytes
  end

  # Parses a string, returning a `MessagePack::Table`.
  def self.unpack(string_or_io : (String | IO))
    case string_or_io
    when String
      Parser.new(StringIO.new(string_or_io)).parse
    when IO
      Parser.new(string_or_io).parse
    end
  end

  def self.parse(string_or_io : (String | IO))
    unpack(string_or_io)
  end
end

require "./message_pack/*"
require "../slice_io"
