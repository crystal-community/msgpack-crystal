# :nodoc:
class MessagePack::Token
  enum Type
    Eof
    Null
    False
    True
    Array
    Hash
    Structure
    Int
    Uint
    Float
    String
    Binary

    def to_s
      super.upcase
    end
  end

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
    @type = Type::Eof
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
    when .string?
      @string_value.inspect(io)
    when .binary?
      @binary_value.inspect(io)
    when .int?
      io << @int_value
    when .float?
      io << @float_value
    else
      io << @type
    end
  end
end
