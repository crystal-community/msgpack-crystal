module MessagePack
  # Represents a possible type inside a MessagePack Array or MessagePack Hash (Table)
  alias Type = Nil | Bool | Int64 | UInt64 | Float64 | String | Array(Type) | Hash(Type, Type)

  # A MessagePack Table. Just a convenience alias.
  alias Table = Hash(String, Type)

  # Parses a string, returning a `MessagePack::Table`.
  def self.unpack(string_or_io : (String | IO))
    case string_or_io
    when String
      Parser.new(StringIO.new(string_or_io)).parse
    when IO
      Parser.new(string_or_io).parse
    end
  end
end

require "./message_pack/*"
require "../slice_io"