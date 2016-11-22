module MessagePack
  class Error < Exception; end

  # Represents a possible type inside a MessagePack Array or MessagePack Hash (Table)
  alias Type = Nil | Bool | Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64 | Float32 | Float64 | String | Bytes | Array(Type) | Hash(Type, Type)

  # A MessagePack Table. Just a convenience alias.
  alias Table = Hash(String, Type)

  def self.pack(value : Type)
    Packer.new.write(value).to_slice
  end

  # Parses a string, returning a `MessagePack::Table`.
  def self.unpack(string_or_io : (String | IO))
    io = string_or_io.is_a?(String) ? IO::Memory.new(string_or_io) : string_or_io
    Unpacker.new(io).read
  end
end

require "./message_pack/*"
