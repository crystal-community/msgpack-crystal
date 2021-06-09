class MessagePack::IOUnpackerZeroCopy < MessagePack::IOUnpacker
  def initialize(io : IO)
    @lexer = MessagePack::LexerZeroCopy.new(io)
  end
end
