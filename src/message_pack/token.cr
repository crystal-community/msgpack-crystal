# :nodoc:
class MessagePack::Token
  property :type

  property :binary_value
  property :string_value
  property :int_value
  property :uint_value
  property :float_value
  property :byte_number
  property :size
  property :used

  @size : Int64
  @int_value : Int::Signed
  @uint_value : Int::Unsigned
  @float_value : Float32 | Float64

  def initialize
    @type = :EOF
    @byte_number = 0
    @binary_value = Slice(UInt8).new(0)
    @string_value = ""
    @int_value = 0_i8
    @uint_value = 0_u8
    @float_value = 0.0_f32

    @size = 0_i64
    @used = true
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
    when :BINARY
      @binary_value.inspect(io)
    when :INT
      io << @int_value
    when :FLOAT
      io << @float_value
    else
      io << @type
    end
  end
end
