class MessagePack::TokensUnpacker < MessagePack::Unpacker
  EOF = MessagePack::Token.new

  def initialize(@tokens : Array(Token))
    @pos = 0
    @used_id = 0
    @tokens.each { |t| t.used = false }
    @token = @tokens.size > 0 ? @tokens[@pos] : EOF
  end

  def token : Token
    @token
  end

  def next_token : Token
    token = prefetch_token
    token.used = true
    token
  end

  def prefetch_token : Token
    return @token unless @token.used
    @pos += 1

    return @token if @pos >= @tokens.size

    @token = @tokens[@pos]
  end
end
