# :nodoc:
class MessagePack::Token
  property :type

  property :binary_value
  property :string_value
  property int_value : Int8 | Int16 | Int32 | Int64
  property uint_value : UInt8 | UInt16 | UInt32 | UInt64
  property float_value : Float32 | Float64
  property :byte_number
  property size : Int64
  property :used

  def initialize
    @type = :EOF
    @byte_number = 0
    @binary_value = Bytes.new(0)
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
    when :nil
      io << :nil
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
