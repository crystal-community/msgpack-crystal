# :nodoc:
module MessagePack::Token
  record NullT, byte_number : Int32
  record BoolT, byte_number : Int32, value : Bool
  record ArrayT, byte_number : Int32, size : UInt32
  record HashT, byte_number : Int32, size : UInt32
  record IntT, byte_number : Int32, value : Int8 | UInt8 | Int16 | UInt16 | Int32 | UInt32 | Int64 | UInt64
  record FloatT, byte_number : Int32, value : Float64
  record StringT, byte_number : Int32, value : String
  record BytesT, byte_number : Int32, value : Bytes
  record ExtT, byte_number : Int32, type_id : Int8, size : UInt32, bytes : Bytes

  alias T = NullT | BoolT | ArrayT | HashT | IntT | FloatT | StringT | BytesT | ExtT

  def self.to_s(token)
    case token
    when StringT
      s = token.value
      String.build do |io|
        io << "StringT(\""
        if s.bytesize > 10
          io.write Bytes.new(s.to_unsafe, 10)
          io << "..."
        else
          io << s
        end
        io << "\")"
      end
    when BytesT
      "BytesT(#{token.value.bytesize})"
    when IntT
      "IntT(#{token.value})"
    when FloatT
      "FloatT(#{token.value})"
    when BoolT
      "BoolT[#{token.value}]"
    when NullT
      "NullT"
    when ArrayT
      "ArrayT[#{token.size}]"
    when HashT
      "HashT[#{token.size}]"
    when ExtT
      "ExtT[#{token.type_id}, #{token.size}]"
    else
      token.inspect
    end
  end
end
