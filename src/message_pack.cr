module MessagePack
  VERSION = "0.13.1"

  # Represents MessagePack Type
  alias Type = Nil | Bool | Int64 | Float64 | String | Array(Type) | Hash(Type, Type)

  # A MessagePack Table. Just a convenience alias.
  alias Table = Hash(String, Type)

  def self.pack(value : Type)
    Packer.new.write(value).to_slice
  end

  # Parses a string, returning a `MessagePack::Table`.
  def self.unpack(string_or_io : (String | IO))
    IOUnpacker.new(string_or_io).read
  end
end

require "./message_pack/*"
