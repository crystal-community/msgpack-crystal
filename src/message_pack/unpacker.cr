require "./lexer"

abstract class MessagePack::Unpacker
  abstract def current_token : Token::T
  abstract def read_token : Token::T
  abstract def finish_token!

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
    when Token::BytesT
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
    when Token::ExtT
      unexpected_token(token)
    else
      raise EofError.new(token.byte_number)
    end
  end

  private def read_array_body
    read_type(Token::ArrayT) do |token|
      Array(Type).new(token.size) { read_value }
    end
  end

  private def read_hash_body
    read_type(Token::HashT) do |token|
      hash = Hash(Type, Type).new(initial_capacity: token.size)
      token.size.times { hash[read_value] = read_value }
      hash
    end
  end

  # ======================= Read typed values ==================

  def read_nil
    read_type(Token::NullT) { nil }
  end

  def read_bool
    read_type(Token::BoolT) { |token| token.value }
  end

  def read_numeric
    case token = current_token
    when Token::IntT, Token::FloatT
      finish_token!
      token.value
    else
      unexpected_token(token, "IntT or FloatT")
    end
  end

  def read_int
    read_type(Token::IntT) { |token| token.value }
  end

  def read_float
    read_type(Token::FloatT) { |token| token.value }
  end

  def read_string
    case token = current_token
    when Token::StringT
      finish_token!
      token.value
    when Token::BytesT
      finish_token!
      String.new token.value
    else
      unexpected_token(token, "StringT or BytesT")
    end
  end

  def read_bytes
    case token = current_token
    when Token::StringT
      finish_token!
      token.value.to_slice
    when Token::BytesT
      finish_token!
      token.value
    else
      unexpected_token(token, "BytesT or StringT")
    end
  end

  def read_array_size
    read_type(Token::ArrayT, finish_token: false) { |token| token.size }
  end

  def read_array
    read_array_body
  end

  def read_hash_size
    read_type(Token::HashT, finish_token: false) { |token| token.size }
  end

  def read_hash
    read_hash_body
  end

  # =============== Consuming array and hash ==================

  def consume_array
    read_type(Token::ArrayT) do |token|
      token.size.times { yield }
    end
  end

  def consume_hash
    read_type(Token::HashT) do |token|
      token.size.times { yield }
    end
  end

  def consume_table
    read_type(Token::HashT) do |token|
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
    else
      # nothing more to do
    end
  end

  def read_ext(type_id : Int8)
    case token = current_token
    when MessagePack::Token::ExtT
      if token.type_id == type_id
        finish_token!
        io = IO::Memory.new(token.bytes)
        yield(token.size, io)
      else
        raise MessagePack::TypeCastError.new("Unknown type_id #{token.type_id}, expected #{type_id}", token.byte_number)
      end
    else
      unexpected_token(token, "ExtT")
    end
  end

  # ======================= Read Node ==================

  def read_node : Node
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
    else
      # nothing more to do
    end

    true
  end

  # ========================= Type cast ======================

  private macro read_type(type, finish_token = true, &block)
    case token = current_token
    when {{type}}
      {% if finish_token %}finish_token!{% end %}
      {{ block.body }}
    else
      unexpected_token(token, {{type.stringify.split("::").last}})
    end
  end

  def unexpected_token(token, expected = nil)
    message = "Unexpected token #{Token.to_s(token)}"
    message += " expected #{expected}" if expected
    raise TypeCastError.new(message, token.byte_number)
  end
end

require "./unpacker/*"
