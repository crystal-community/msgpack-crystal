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
    it_packs(UInt32::MAX.{{method.id}} + 1, UInt8[0xCF, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00]) # TODO
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
end
