module MessagePack
  VERSION = "0.16.1"

  # Represents MessagePack Type
  alias Type = Nil | Bool | Float64 | String | Bytes | Array(Type) | Hash(Type, Type) | Int8 | UInt8 | Int16 | UInt16 | Int32 | UInt32 | Int64 | UInt64

  # A MessagePack Table. Just a convenience alias.
  alias Table = Hash(String, Type)

  def self.pack(value : Type)
    Packer.new.write(value).to_slice
  end

  # Parses a string, returning a `MessagePack::Table`.
  def self.unpack(string_or_io : (Bytes | String | IO))
    IOUnpacker.new(string_or_io).read
  end
end

require "./message_pack/*"
