# :nodoc:
module MessagePack::Token
  record NullT, byte_number : Int32
  record BoolT, byte_number : Int32, value : Bool
  record ArrayT, byte_number : Int32, size : UInt32
  record HashT, byte_number : Int32, size : UInt32
  record IntT, byte_number : Int32, value : Int64, bytesize : UInt8, signed : Bool
  record FloatT, byte_number : Int32, value : Float64
  record StringT, byte_number : Int32, value : String, binary : Bool

  alias T = NullT | BoolT | ArrayT | HashT | IntT | FloatT | StringT

  def self.to_s(token)
    case token
    when StringT
      s = token.value
      if s.bytesize > 10
        "\"#{s[0..10]}...\""
      else
        s.inspect
      end
    when IntT
      token.value.inspect
    when FloatT
      token.value.inspect
    when BoolT
      token.value.inspect
    when NullT
      "nil"
    when ArrayT
      "Array[#{token.size}]"
    when HashT
      "Hash[#{token.size}]"
    else
      token.inspect
    end
  end
end
