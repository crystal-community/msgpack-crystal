require "./spec_helper"

private def it_lexes(description, expected_type, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description} from IO", file, line do
    lexer = MessagePack::Lexer.new IO::Memory.new(string)
    token = lexer.read_token
    token.class.should eq(expected_type)
  end
end

private def it_lexes_int(description, int_value, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description} from IO", file, line do
    lexer = MessagePack::Lexer.new IO::Memory.new(string)
    token = lexer.read_token
    case token
    when MessagePack::Token::IntT
      token.value.should eq int_value
    else
      raise "unexpected token type #{token.inspect}"
    end
  end
end

private def it_lexes_float(description, float_value, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description}", file, line do
    lexer = MessagePack::Lexer.new IO::Memory.new(string)
    token = lexer.read_token
    case token
    when MessagePack::Token::FloatT
      token.value.should eq float_value
    else
      raise "unexpected token type #{token.inspect}"
    end
  end
end

private def it_lexes_string(description, string_value, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description}", file, line do
    lexer = MessagePack::Lexer.new IO::Memory.new(string)
    token = lexer.read_token
    case token
    when MessagePack::Token::StringT
      token.value.should eq string_value
    else
      raise "unexpected token type #{token.inspect}"
    end
  end
end

private def it_lexes_bytes(description, decoded, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description}", file, line do
    lexer = MessagePack::Lexer.new IO::Memory.new(string)
    token = lexer.read_token
    case token
    when MessagePack::Token::BytesT
      token.value.should eq decoded
    else
      raise "unexpected token type #{token.inspect}"
    end
  end
end

private def it_lexes_arrays(description, size, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description}", file, line do
    lexer = MessagePack::Lexer.new IO::Memory.new(string)
    token = lexer.read_token
    case token
    when MessagePack::Token::ArrayT
      token.size.should eq size
    else
      raise "unexpected token type #{token.inspect}"
    end
  end
end

private def it_lexes_hashes(description, size, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description}", file, line do
    lexer = MessagePack::Lexer.new IO::Memory.new(string)
    token = lexer.read_token
    case token
    when MessagePack::Token::HashT
      token.size.should eq size
    else
      raise "unexpected token type #{token.inspect}"
    end
  end
end

describe MessagePack::Lexer do
  it_lexes("nil", MessagePack::Token::NullT, UInt8[0xC0u8])
  it_lexes("false", MessagePack::Token::BoolT, UInt8[0xC2u8])
  it_lexes("true", MessagePack::Token::BoolT, UInt8[0xC3u8])

  it_lexes_int("zero", 0, UInt8[0x00])
  it_lexes_int("fix num", 127, UInt8[0x7f])
  it_lexes_int("small integers", 128, UInt8[0xcc, 0x80])
  it_lexes_int("medium integers", 256, UInt8[0xcd, 0x01, 0x00])
  it_lexes_int("large integers", UInt32::MAX, UInt8[0xce, 0xff, 0xff, 0xff, 0xff])
  it_lexes_int("huge integers", UInt64::MAX, UInt8[0xcf, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])

  it_lexes_int("-1", -1, UInt8[0xff])
  it_lexes_int("-33", -33, UInt8[0xd0, 0xdf])
  it_lexes_int("-129", -129, UInt8[0xd1, 0xff, 0x7f])
  it_lexes_int("-8444910", -8444910, UInt8[0xd2, 0xff, 0x7f, 0x24, 0x12])
  it_lexes_int("-41957882392009710", -41957882392009710, UInt8[0xd3, 0xff, 0x6a, 0xef, 0x87, 0x3c, 0x7f, 0x24, 0x12])
  it_lexes_int("negative integers", -1, UInt8[0xff])

  it_lexes_float("1.0", 1.0, UInt8[0xcb, 0x3f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
  it_lexes_float("small floats", 3.14, UInt8[203, 64, 9, 30, 184, 81, 235, 133, 31])
  it_lexes_float("big floats", Math::PI * 1_000_000_000_000_000_000, UInt8[203, 67, 197, 204, 150, 239, 209, 25, 37])
  it_lexes_float("negative floats", -2.1, UInt8[0xcb, 0xc0, 0x00, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcd])

  it_lexes_string("strings", "hello world", UInt8[0xAB] + "hello world".bytes)
  it_lexes_string("empty strings", "", UInt8[0xA0])
  it_lexes_string("medium strings", "x" * 0xdd, UInt8[0xD9, 0xDD] + ("x" * 0xDD).bytes)
  it_lexes_string("big strings", "x" * 0xdddd, UInt8[0xDA, 0xDD, 0xDD] + ("x" * 0xdddd).bytes)
  it_lexes_string("huge strings", "x" * 0x0000dddd, UInt8[0xDB, 0x00, 0x00, 0xDD, 0xDD] + ("x" * 0x0000dddd).bytes)

  it_lexes_bytes("medium binary", Bytes.new(0x5, 7), UInt8[0xc4, 0x05] + ("\a" * 0x5).bytes)
  it_lexes_bytes("big binary", Bytes.new(0x100, 7), UInt8[0xc5, 0x01, 0x00] + ("\a" * 0x100).bytes)
  it_lexes_bytes("huge binary", Bytes.new(0x10000, 7), UInt8[0xc6, 0x00, 0x01, 0x00, 0x00] + ("\a" * 0x10000).bytes)

  it_lexes_arrays("empty arrays", 0, UInt8[0x90])
  it_lexes_arrays("small arrays", 2, UInt8[0x92, 0x01, 0x02])
  it_lexes_arrays("medium arrays", 0x111, UInt8[0xdc, 0x01, 0x11] + UInt8[0x22, 0xc2])
  it_lexes_arrays("big arrays", 0x11111, UInt8[0xdd, 0x00, 0x01, 0x11, 0x11] + UInt8[0x22, 0xc2])

  it_lexes_hashes("empty hashes", 0, UInt8[0x80])
  it_lexes_hashes("small hashes", 1, UInt8[0x81, 0xa3] + "foo".bytes + UInt8[0xa3] + "bar".bytes)
  it_lexes_hashes("medium hashes", 1, UInt8[0xde, 0x00, 0x01, 0xa3] + "foo".bytes + UInt8[0xa3] + "bar".bytes)
  it_lexes_hashes("big hashes", 1, UInt8[0xdf, 0x00, 0x00, 0x00, 0x01, 0xa3] + "foo".bytes + UInt8[0xa3] + "bar".bytes)

  context "next_token" do
    it "only calls next byte before reading not after reading" do
      bytes = UInt8[0xff, 0xff]
      string = String.new(bytes.to_unsafe, bytes.size)
      lexer = MessagePack::Lexer.new(IO::Memory.new(string))
      lexer.read_token.should eq MessagePack::Token::IntT.new(0, -1)
      lexer.read_token.should eq MessagePack::Token::IntT.new(1, -1)
      expect_raises(MessagePack::EofError) do
        lexer.read_token
      end
    end
  end
end
