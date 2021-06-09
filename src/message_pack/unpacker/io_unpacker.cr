class MessagePack::IOUnpacker < MessagePack::Unpacker
  def initialize(io : IO)
    @lexer = MessagePack::Lexer.new(io)
  end

  def self.new(bytes : Bytes | String)
    io = IO::Memory.new(bytes)
    new(io)
  end

  def self.new(array : Array(UInt8))
    bytes = Bytes.new(array.to_unsafe, array.size)
    io = IO::Memory.new(bytes)
    new(io)
  end

  @[AlwaysInline]
  def current_token : Token::T
    @lexer.current_token
  end

  @[AlwaysInline]
  def read_token : Token::T
    @lexer.read_token
  end

  @[AlwaysInline]
  def finish_token!
    @lexer.finish_token!
  end
end
