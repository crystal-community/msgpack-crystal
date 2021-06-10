class MessagePack::IOUnpackerZeroCopy < MessagePack::IOUnpacker
  def initialize(io : IO)
    @lexer = MessagePack::LexerZeroCopy.new(io)
  end

  def self.new(bytes : Bytes | String)
    io = IO::Memory.new(bytes)
    self.new(io)
  end

  def self.new(array : Array(UInt8))
    bytes = Bytes.new(array.to_unsafe, array.size)
    io = IO::Memory.new(bytes)
    new(io)
  end
end
