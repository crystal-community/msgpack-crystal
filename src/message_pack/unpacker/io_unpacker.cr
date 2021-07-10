class MessagePack::IOUnpacker < MessagePack::Unpacker
  @lexer : MessagePack::Lexer

  def initialize(io : IO, zero_copy = false)
    @lexer = if zero_copy
               MessagePack::Lexer::ZeroCopy.new(io)
             else
               MessagePack::Lexer.new(io)
             end
  end

  def self.new(bytes : Bytes | String, zero_copy = false)
    io = IO::Memory.new(bytes)
    self.new(io, zero_copy)
  end

  def self.new(array : Array(UInt8), zero_copy = false)
    bytes = Bytes.new(array.to_unsafe, array.size)
    io = IO::Memory.new(bytes)
    new(io, zero_copy)
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
