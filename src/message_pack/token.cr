# :nodoc:
class MessagePack::Token
  property :type

  property :string_value
  property :slice_value
  property :int_value
  property :uint_value
  property :float_value
  property :byte_number
  property :size

  def initialize
    @type = :EOF
    @byte_number = 0
    @string_value = ""
    @slice_value = nil
    @int_value = 0_i64
    @uint_value = 0_u64
    @float_value = 0.0_f64

    @size = 0
  end

  def int_value=(int_value)
    @int_value = int_value.to_i64
  end

  def uint_value=(uint_value)
    @uint_value = uint_value.to_u64
  end

  def float_value=(float_value)
    @float_value = float_value.to_f64
  end

  def to_s(io)
    case @type
    when :NIL
      io << :NIL
    when :STRING
      @string_value.inspect(io)
    when :INT
      io << @int_value
    when :FLOAT
      io << @float_value
    else
      io << @type
    end
  end
end
