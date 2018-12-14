require "./lexer"

abstract class MessagePack::Unpacker
  abstract def current_token : Token
  abstract def read_token : Token
  abstract def finish_token! : Token

  # ================== read untyped values =======================

  def read : Type
    read_value
  end

  def read_value : Type
    case token = current_token
    when Token::IntT
      finish_token!
      token.value
    when Token::FloatT
      finish_token!
      token.value
    when Token::StringT
      finish_token!
      token.value
    when Token::BoolT
      finish_token!
      token.value
    when Token::NullT
      finish_token!
      nil
    when Token::ArrayT
      read_array_body
    when Token::HashT
      read_hash_body
    else
      raise EofError.new(token.byte_number)
    end
  end

  private def read_array_body
    read(Token::ArrayT) do |token|
      Array(Type).new(token.size) { read_value }
    end
  end

  private def read_hash_body
    read(Token::HashT) do |token|
      hash = Hash(Type, Type).new(initial_capacity: token.size)
      token.size.times { hash[read_value] = read_value }
      hash
    end
  end

  # ======================= Read typed values ==================

  def read_nil
    read(Token::NullT) { nil }
  end

  def read_bool
    read(Token::BoolT) { |token| token.value }
  end

  def read_numeric : Int64 | Float64
    read(Token::IntT, Token::FloatT) { |token| token.value }
  end

  def read_int
    read(Token::IntT) { |token| token.value }
  end

  def read_float
    read(Token::FloatT) { |token| token.value }
  end

  def read_string
    read(Token::StringT) { |token| token.value }
  end

  def read_array_size
    read(Token::ArrayT, finish_token: false) { |token| token.size }
  end

  def read_array
    read_array_size
    read_array_body
  end

  def read_hash_size
    read(Token::HashT, finish_token: false) { |token| token.size }
  end

  def read_hash
    read_hash_size
    read_hash_body
  end

  # =============== Consuming array and hash ==================

  def consume_array
    read(Token::ArrayT) do |token|
      token.size.times { yield }
    end
  end

  def consume_hash
    read(Token::HashT) do |token|
      token.size.times { yield }
    end
  end

  def consume_table
    read(Token::HashT) do |token|
      token.size.times { yield(read_string) }
    end
  end

  # ========================== Helper methods ======================

  def read_nil_or
    if current_token.is_a?(Token::NullT)
      finish_token!
      nil
    else
      yield
    end
  end

  def skip_value
    case token = read_token
    when Token::ArrayT
      token.size.times { skip_value }
    when Token::HashT
      token.size.times { skip_value; skip_value }
    end
  end

  # ======================= Read Node ==================

  def read_node
    node = Node.new
    _read_node(node)
    node
  end

  private def _read_node(node)
    token = read_token
    node.tokens << token

    case token
    when Token::ArrayT
      token.size.times { _read_node(node) }
    when Token::HashT
      token.size.times { _read_node(node); _read_node(node) }
    end

    true
  end

  # ========================= Type cast ======================

  private macro read(*types, finish_token = true, &block)
    case token = current_token
    when {{*types}}
      {% if finish_token %}finish_token!{% end %}
      {{ block.body }}
    else
      unexpected_token(token, {{types.map(&.stringify).join(", ")}})
    end
  end

  def unexpected_token(token, expected = nil)
    message = "Unexpected token '#{Token.to_s(token)}'"
    message += " expected #{expected}" if expected
    raise TypeCastError.new(message, token.byte_number)
  end
end

require "./unpacker/*"
