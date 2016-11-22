require "./spec_helper"

private def it_lexes(description, expected_type, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description} from IO", file, line do
    lexer = Lexer.new string
    token = lexer.next_token
    token.type.should eq(expected_type)
  end
end

private def it_lexes_int(description, int_value, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description} from IO", file, line do
    lexer = Lexer.new string
    token = lexer.next_token
    token.type.should eq(:INT)
    token.int_value.should eq(int_value)
  end
end

private def it_lexes_uint(description, uint_value, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description} from IO", file, line do
    lexer = Lexer.new string
    token = lexer.next_token
    token.type.should eq(:UINT)
    token.uint_value.should eq(uint_value)
  end
end

private def it_lexes_float(description, float_value, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description}", file, line do
    lexer = Lexer.new string
    token = lexer.next_token
    token.type.should eq(:FLOAT)
    token.float_value.should eq(float_value)
  end
end

private def it_lexes_string(description, string_value, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description}", file, line do
    lexer = Lexer.new string
    token = lexer.next_token
    token.type.should eq(:STRING)
    token.string_value.should eq(string_value)
  end
end

private def it_lexes_binary(description, string_value, bytes, file = __FILE__, line = __LINE__)
  io = IO::Memory.new(as_slice(bytes))
  binary_value = string_value.to_slice

  it "lexes #{description}", file, line do
    lexer = Lexer.new io
    token = lexer.next_token
    token.type.should eq(:BINARY)
    token.binary_value.should eq(binary_value)
  end
end

private def it_lexes_arrays(description, size, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description}", file, line do
    lexer = Lexer.new string
    token = lexer.next_token
    token.type.should eq(:ARRAY)
    token.size.should eq(size)
  end
end

private def it_lexes_hashes(description, size, bytes, file = __FILE__, line = __LINE__)
  string = Bytes.new(bytes.to_unsafe, bytes.size)

  it "lexes #{description}", file, line do
    lexer = Lexer.new string
    token = lexer.next_token
    token.type.should eq(:HASH)
    token.size.should eq(size)
  end
end

private def it_raises(io, file = __FILE__, line = __LINE__)
  it "raises on lex #{io.inspect}", file, line do
    expect_raises ParseException do
      lexer = Lexer.new(io)
      while lexer.next_token.type != :EOF
        # Nothing
      end
    end
  end
end

describe Lexer do
  it_lexes("EOF", :EOF, UInt8[])
  it_lexes("nil", :nil, UInt8[0xC0u8])
  it_lexes("false", :false, UInt8[0xC2u8])
  it_lexes("true", :true, UInt8[0xC3u8])

  it_lexes_uint("zero", 0, UInt8[0x00])
  it_lexes_uint("fix num", 127, UInt8[0x7f])
  it_lexes_uint("small integers", 128, UInt8[0xcc, 0x80])
  it_lexes_uint("medium integers", 256, UInt8[0xcd, 0x01, 0x00])
  it_lexes_uint("large integers", 2 ** 31 - 1, UInt8[0xce, 0x7f, 0xff, 0xff, 0xff])
  it_lexes_uint("huge integers", 2 ** 64_f64 - 1, UInt8[0xcf, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])

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

  it_lexes_binary("medium binary", "\a" * 0x5, UInt8[0xc4, 0x05] + ("\a" * 0x5).bytes)
  it_lexes_binary("big binary", "\a" * 0x100, UInt8[0xc5, 0x01, 0x00] + ("\a" * 0x100).bytes)
  it_lexes_binary("huge binary", "\a" * 0x10000, UInt8[0xc6, 0x00, 0x01, 0x00, 0x00] + ("\a" * 0x10000).bytes)

  it_lexes_arrays("empty arrays", 0, UInt8[0x90])
  it_lexes_arrays("small arrays", 2, UInt8[0x92, 0x01, 0x02])
  it_lexes_arrays("medium arrays", 0x111, UInt8[0xdc, 0x01, 0x11] + UInt8[0x111, 0xc2])
  it_lexes_arrays("big arrays", 0x11111, UInt8[0xdd, 0x00, 0x01, 0x11, 0x11] + UInt8[0x11111, 0xc2])

  it_lexes_hashes("empty hashes", 0, UInt8[0x80])
  it_lexes_hashes("small hashes", 1, UInt8[0x81, 0xa3] + "foo".bytes + UInt8[0xa3] + "bar".bytes)
  it_lexes_hashes("medium hashes", 1, UInt8[0xde, 0x00, 0x01, 0xa3] + "foo".bytes + UInt8[0xa3] + "bar".bytes)
  it_lexes_hashes("big hashes", 1, UInt8[0xdf, 0x00, 0x00, 0x00, 0x01, 0xa3] + "foo".bytes + UInt8[0xa3] + "bar".bytes)

  context "next_token" do
    it "only calls next byte before reading not after reading" do
      bytes = UInt8[0xff, 0xff]
      string = String.new(bytes.to_unsafe, bytes.size)
      lexer = Lexer.new(string)
      lexer.next_token
      lexer.next_token

      lexer.current_byte.should eq 0xFF

      lexer.next_token
      lexer.current_byte.should eq 0
    end
  end
end
