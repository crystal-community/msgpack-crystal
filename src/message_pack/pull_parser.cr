class MessagePack::PullParser
  getter kind
  getter bool_value
  getter int_value
  getter uint_value
  getter float_value
  getter string_value

  private delegate token, @lexer
  private delegate next_token, @lexer

  def initialize(input)
    @lexer = Lexer.new input
    @kind = :EOF
    @remaining_array_or_hash_items = 0
    @bool_value = false
    @int_value = 0_i64
    @uint_value = 0_u64
    @float_value = 0.0
    @string_value = ""
    @object_stack = [] of Symbol
    @skip_count = 0

    next_token

    case token.type
    when :nil
      @kind = :nil
    when :false
      @kind = :bool
      @bool_value = false
    when :true
      @kind = :bool
      @bool_value = true
    when :INT
      @kind = :int
      @int_value = token.int_value
    when :UINT
      @kind = :uint
      @int_value = token.uint_value
    when :FLOAT
      @kind = :float
      @float_value = token.float_value
    when :STRING
      @kind = :string
      @string_value = token.string_value
    when :ARRAY
      begin_array
    when :HASH
      begin_hash
    else
      unexpected_token
    end
  end

  def read_next
    read_next_internal
    @kind
  end

  private def read_next_internal
    current_kind = @kind

    while true
      case token.type
      when :nil
        @kind = :nil
        next_token_after_value
        return
      when :true
        @kind = :bool
        @bool_value = true
        next_token_after_value
        return
      when :false
        @kind = :bool
        @bool_value = false
        next_token_after_value
        return
      when :INT
        @kind = :int
        @int_value = token.int_value
        next_token_after_value
        return
      when :UINT
        @kind = :Uint
        @uint_value = token.uint_value
        next_token_after_value
        return
      when :FLOAT
        @kind = :float
        @float_value = token.float_value
        next_token_after_value
        return
      when :STRING
        if current_kind == :begin_object
          @kind = :object_key
          @string_value = token.string_value
          if next_token.type != :":"
            unexpected_token
          end
        else
          @kind = :string
          @string_value = token.string_value
          next_token_after_value
        end
        return
      when :ARRAY
        begin_array
        return
      when :HASH
        begin_hash
        return
      else
        unexpected_token
      end
    end
  end

  private def next_token_after_value
    case next_token.type
    when :",", :"]", :"}"
      # Ok
    else
      if @object_stack.empty?
        @kind = :EOF
      else
        unexpected_token
      end
    end
  end

  private def begin_array
    @kind = :ARRAY
    @object_stack << :ARRAY
    @remaining_array_or_hash_items = token.size

  end

  private def begin_hash
    @kind = :ARRAY
    @object_stack << :HASH
  end

  private def current_object
    @object_stack.last?
  end

  private def expect_kind(kind)
    parse_exception "expected #{kind} but was #{@kind}" unless @kind == kind
  end

  private def unexpected_token
    parse_exception "unexpected token: #{token}"
  end

  private def parse_exception(msg)
    raise ParseException.new(msg, token.byte_number)
  end
end
