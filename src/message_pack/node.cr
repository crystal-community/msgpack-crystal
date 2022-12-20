record MessagePack::Node, tokens : Array(Token::T) = [] of Token::T do
  def to_unpacker
    MessagePack::NodeUnpacker.new(self)
  end

  def self.new(pull : MessagePack::Unpacker)
    pull.read_node
  end
end
