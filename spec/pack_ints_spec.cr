require "./spec_helper"

describe "MessagePack::Packer" do
  {% for method in %w(to_i8 to_u8 to_i16 to_u16 to_i32 to_u32 to_i64 to_u64) %}
    it_packs(0.{{method.id}}, UInt8[0x00])
    it_packs(1.{{method.id}}, UInt8[0x01])
    it_packs(127.{{method.id}}, UInt8[0x7F])
  {% end %}

  {% for method in %w(to_u8 to_i16 to_u16 to_i32 to_u32 to_i64 to_u64) %}
    it_packs(128.{{method.id}}, UInt8[0xCC, 0x80])
    it_packs(255.{{method.id}}, UInt8[0xCC, 0xFF])
  {% end %}

  {% for method in %w(to_i16) %}
    it_packs(256.{{method.id}}, UInt8[0xCD, 0x01, 0x00])
    it_packs(Int16::MAX.{{method.id}}, UInt8[0xCD, 0x7F, 0xFF])
  {% end %}

  {% for method in %w(to_u16 to_i32 to_u32 to_i64 to_u64) %}
    it_packs(256.{{method.id}}, UInt8[0xCD, 0x01, 0x00])
    it_packs(Int16::MAX.{{method.id}}, UInt8[0xCD, 0x7F, 0xFF])
    it_packs(UInt16::MAX.{{method.id}}, UInt8[0xCD, 0xFF, 0xFF])
  {% end %}

  {% for method in %w(to_i32) %}
    it_packs(UInt16::MAX.{{method.id}} + 1, UInt8[0xCE, 0x00, 0x01, 0x00, 0x00])
    it_packs(Int32::MAX.{{method.id}}, UInt8[0xCE, 0x7F, 0xFF, 0xFF, 0xFF])
  {% end %}

  {% for method in %w(to_u32 to_i64 to_u64) %}
    it_packs(UInt16::MAX.{{method.id}} + 1, UInt8[0xCE, 0x00, 0x01, 0x00, 0x00])
    it_packs(Int32::MAX.{{method.id}}, UInt8[0xCE, 0x7F, 0xFF, 0xFF, 0xFF])
    it_packs(UInt32::MAX.{{method.id}}, UInt8[0xCE, 0xFF, 0xFF, 0xFF, 0xFF])
  {% end %}

  {% for method in %w(to_i64) %}
    it_packs(UInt32::MAX.{{method.id}} + 1, UInt8[0xCF, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00])
    it_packs(Int64::MAX.{{method.id}}, UInt8[0xCF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
  {% end %}

  {% for method in %w(to_u64) %}
    it_packs(UInt32::MAX.{{method.id}}.to_u64 + 1, UInt8[0xCF, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00])
    it_packs(Int64::MAX.{{method.id}}, UInt8[0xCF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
    it_packs(UInt64::MAX.{{method.id}}, UInt8[0xCF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
  {% end %}

  {% for method in %w(to_i8 to_i16 to_i32 to_i64) %}
    it_packs(-1.{{method.id}}, UInt8[0xFF])
    it_packs(-32.{{method.id}}, UInt8[0xE0])
  {% end %}

  {% for method in %w(to_i8 to_i16 to_i32 to_i64) %}
    it_packs(-33.{{method.id}}, UInt8[0xD0, 0xDF])
    it_packs(Int8::MIN.{{method.id}}, UInt8[0xD0, 0x80])
  {% end %}

  {% for method in %w(to_i16 to_i32 to_i64) %}
    it_packs(Int8::MIN.{{method.id}} - 1, UInt8[0xD1, 0xFF, 0x7F])
    it_packs(Int16::MIN.{{method.id}}, UInt8[0xD1, 0x80, 0x00])
  {% end %}

  {% for method in %w(to_i32 to_i64) %}
    it_packs(Int16::MIN.{{method.id}} - 1, UInt8[0xD2, 0xFF, 0xFF, 0x7F, 0xFF])
    it_packs(Int32::MIN.{{method.id}}, UInt8[0xD2, 0x80, 0x00, 0x00, 0x00])
  {% end %}

  {% for method in %w(to_i64) %}
    it_packs(Int32::MIN.{{method.id}} - 1, UInt8[0xD3, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF])
    it_packs(Int64::MIN.{{method.id}}, UInt8[0xD3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
  {% end %}

  describe "casting ints" do
    context "int8" do
      it { Int8.from_msgpack(1.to_msgpack).should eq 1_i8 }
      it { expect_raises(OverflowError) { Int8.from_msgpack(129.to_msgpack) } }
      it { Int8.from_msgpack(-1.to_msgpack).should eq -1_i8 }
      it { Int8.from_msgpack(-54.to_msgpack).should eq -54_i8 }
      it { expect_raises(OverflowError) { Int8.from_msgpack(-129.to_msgpack) } }
    end

    context "uint8" do
      it { UInt8.from_msgpack(1.to_msgpack).should eq 1_u8 }
      it { UInt8.from_msgpack(129.to_msgpack).should eq 129_u8 }
      it { UInt8.from_msgpack(UInt8::MAX.to_msgpack).should eq UInt8::MAX }
      it { expect_raises(OverflowError) { UInt8.from_msgpack(-1.to_msgpack) } }
      it { expect_raises(OverflowError) { UInt8.from_msgpack(257.to_msgpack) } }
    end

    context "int16" do
      it { Int16.from_msgpack(1.to_msgpack).should eq 1_i16 }
      it { Int16.from_msgpack(129.to_msgpack).should eq 129_i16 }
      it { Int16.from_msgpack(UInt8::MAX.to_msgpack).should eq UInt8::MAX }
      it { expect_raises(OverflowError) { Int16.from_msgpack(UInt16::MAX.to_msgpack) } }
      it { Int16.from_msgpack(-1.to_msgpack).should eq -1_i16 }
      it { Int16.from_msgpack(-129.to_msgpack).should eq -129_i16 }
      it { Int16.from_msgpack(Int16::MIN.to_msgpack).should eq Int16::MIN }
      it { expect_raises(OverflowError) { Int16.from_msgpack(Int32::MIN.to_msgpack) } }
    end

    context "uint16" do
      it { UInt16.from_msgpack(1.to_msgpack).should eq 1_u16 }
      it { UInt16.from_msgpack(129.to_msgpack).should eq 129_u16 }
      it { UInt16.from_msgpack(Int16::MAX.to_msgpack).should eq Int16::MAX }
      it { UInt16.from_msgpack(UInt16::MAX.to_msgpack).should eq UInt16::MAX }
      it { expect_raises(OverflowError) { UInt16.from_msgpack(-1.to_msgpack).should eq 65535 } }
      it { expect_raises(OverflowError) { UInt16.from_msgpack(Int16::MIN.to_msgpack) } }
      it { expect_raises(OverflowError) { UInt16.from_msgpack(Int32::MAX.to_msgpack) } }
    end

    context "int32" do
      it { Int32.from_msgpack(1.to_msgpack).should eq 1 }
      it { Int32.from_msgpack(129.to_msgpack).should eq 129 }
      it { Int32.from_msgpack(Int16::MAX.to_msgpack).should eq Int16::MAX }
      it { Int32.from_msgpack(Int32::MAX.to_msgpack).should eq Int32::MAX }
      it { expect_raises(OverflowError) { Int32.from_msgpack(UInt32::MAX.to_msgpack) } }
      it { Int32.from_msgpack(-1.to_msgpack).should eq -1 }
      it { Int32.from_msgpack(-129.to_msgpack).should eq -129 }
      it { Int32.from_msgpack(Int16::MIN.to_msgpack).should eq Int16::MIN }
      it { Int32.from_msgpack(Int32::MIN.to_msgpack).should eq Int32::MIN }
      it { expect_raises(OverflowError) { Int32.from_msgpack(Int64::MIN.to_msgpack) } }
    end

    context "uint32" do
      it { UInt32.from_msgpack(1.to_msgpack).should eq 1 }
      it { UInt32.from_msgpack(129.to_msgpack).should eq 129 }
      it { UInt32.from_msgpack(Int16::MAX.to_msgpack).should eq Int16::MAX }
      it { UInt32.from_msgpack(Int32::MAX.to_msgpack).should eq Int32::MAX }
      it { UInt32.from_msgpack(UInt32::MAX.to_msgpack).should eq UInt32::MAX }
      it { expect_raises(OverflowError) { UInt32.from_msgpack(-1.to_msgpack).should eq 4294967295 } }
      it { expect_raises(OverflowError) { UInt32.from_msgpack(Int16::MIN.to_msgpack).should eq 4294934528 } }
      it { expect_raises(OverflowError) { UInt32.from_msgpack(Int32::MIN.to_msgpack) } }
      it { expect_raises(OverflowError) { UInt32.from_msgpack(Int64::MAX.to_msgpack) } }
    end

    context "int64" do
      it { Int64.from_msgpack(1.to_msgpack).should eq 1 }
      it { Int64.from_msgpack(129.to_msgpack).should eq 129 }
      it { Int64.from_msgpack(Int16::MAX.to_msgpack).should eq Int16::MAX }
      it { Int64.from_msgpack(Int32::MAX.to_msgpack).should eq Int32::MAX }
      it { Int64.from_msgpack(UInt32::MAX.to_msgpack).should eq UInt32::MAX }
      it { Int64.from_msgpack(-1.to_msgpack).should eq -1 }
      it { Int64.from_msgpack(-129.to_msgpack).should eq -129 }
      it { Int64.from_msgpack(Int16::MIN.to_msgpack).should eq Int16::MIN }
      it { Int64.from_msgpack(Int32::MIN.to_msgpack).should eq Int32::MIN }
      it { Int64.from_msgpack(Int64::MIN.to_msgpack).should eq Int64::MIN }

      it { expect_raises(OverflowError) { Int64.from_msgpack(UInt64::MAX.to_msgpack) } }
    end

    context "uint64" do
      it { UInt64.from_msgpack(1.to_msgpack).should eq 1 }
      it { UInt64.from_msgpack(129.to_msgpack).should eq 129 }
      it { UInt64.from_msgpack(Int16::MAX.to_msgpack).should eq Int16::MAX }
      it { UInt64.from_msgpack(Int32::MAX.to_msgpack).should eq Int32::MAX }
      it { UInt64.from_msgpack(UInt32::MAX.to_msgpack).should eq UInt32::MAX }
      it { UInt64.from_msgpack(UInt64::MAX.to_msgpack).should eq UInt64::MAX }

      it { expect_raises(OverflowError) { UInt64.from_msgpack(-1.to_msgpack).should eq UInt64::MAX } }
      it { expect_raises(OverflowError) { UInt64.from_msgpack(Int16::MIN.to_msgpack).should eq 18446744073709518848_u64 } }
      it { expect_raises(OverflowError) { UInt64.from_msgpack(Int32::MIN.to_msgpack).should eq 18446744071562067968_u64 } }
      it { expect_raises(OverflowError) { UInt64.from_msgpack(Int64::MIN.to_msgpack) } }
    end
  end
end
