class MessagePack::IOUnpacker < MessagePack::Unpacker
  def initialize(string_or_io)
    @lexer = MessagePack::Lexer.new(string_or_io)
  end

  def self.new(array : Array(UInt8))
    slice = Bytes.new(array.to_unsafe, array.size)
    new(slice)
  end

  delegate current_token, to: @lexer
  delegate finish_token!, to: @lexer
  delegate read_token, to: @lexer
end
