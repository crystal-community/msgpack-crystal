class MessagePack::LexerZeroCopy < MessagePack::Lexer
  protected def io_read_fully(size) : Bytes
    io = @io.as IO::Memory
    bytes = io.to_slice[io.pos, size]
    io.pos += size
    bytes
  end
end

