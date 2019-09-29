class MessagePack::IOUnpacker < MessagePack::Unpacker
  def initialize(string_or_io)
    @lexer = MessagePack::Lexer.new(string_or_io)
  end

  def self.new(array : Array(UInt8))
    slice = Bytes.new(array.to_unsafe, array.size)
    new(slice)
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
