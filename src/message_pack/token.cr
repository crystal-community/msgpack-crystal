# :nodoc:
class MessagePack::Token
  property :type

  property :string_value
  property :int_value
  property :uint_value
  property :float_value
  property :byte_number
  property :size

  @size : Int64

  def initialize
    @type = :EOF
    @byte_number = 0
    @string_value = ""
    @int_value = 0_i8
    @uint_value = 0_u8
    @float_value = 0.0_f32

    @size = 0_i64
  end

  def size=(size)
    @size = size.to_i64
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
