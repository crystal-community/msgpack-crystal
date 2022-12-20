module MessagePack
  VERSION = "1.3.4"

  # Represents MessagePack Type
  alias Type = Nil | Bool | Float64 | String | Bytes | Array(Type) | Hash(Type, Type) | Int8 | UInt8 | Int16 | UInt16 | Int32 | UInt32 | Int64 | UInt64

  # A MessagePack Table. Just a convenience alias.
  alias Table = Hash(String, Type)

  def self.pack(value : Type)
    Packer.new.write(value).to_slice
  end

  def self.unpack(string_or_io : String | IO | Bytes) : Any
    Any.from_msgpack(string_or_io)
  end
end

require "./message_pack/*"
