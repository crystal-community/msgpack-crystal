class MessagePack::NodeUnpacker < MessagePack::Unpacker
  @token : Token::T

  def initialize(@node : Node)
    @token = Token::NullT.new(0)
    @token_finished = true
    @pos = 0
  end

  def current_token : Token::T
    if @token_finished
      @token = next_token
      @token_finished = false
    end

    @token
  end

  def finish_token!
    @token_finished = true
  end

  def read_token : Token::T
    @token = next_token if @token_finished
    finish_token!
    @token
  end

  private def next_token
    if @pos < @node.tokens.size
      token = @node.tokens[@pos]
      @pos += 1
      token
    else
      raise EofError.new(@token.byte_number)
    end
  end
end
