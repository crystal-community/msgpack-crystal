require "./spec_helper"

struct CMessagePackAttr1
  include MessagePack::ArraySerializable

  @a : Int32
  @b : Int32
  @c : Int32

  def initialize(@a, @b, @c)
  end
end

struct CMessagePackAttr2
  include MessagePack::ArraySerializable

  @[MessagePack::Field(id: 2)]
  @a : Int32

  @b : Int32

  @[MessagePack::Field(id: 0)]
  @c : Int32

  def initialize(@a, @b, @c)
  end
end

struct CMessagePackAttr3
  include MessagePack::ArraySerializable

  @[MessagePack::Field(id: 5)]
  @a : Int32

  @[MessagePack::Field(id: 3)]
  @b : Int32

  @[MessagePack::Field(id: 1)]
  @c : Int32

  def initialize(@a, @b, @c)
  end
end

@[MessagePack::ArraySerializable::Options(variables: 8)]
struct CMessagePackAttr4
  include MessagePack::ArraySerializable

  @[MessagePack::Field(id: 5)]
  @a : Int32

  @[MessagePack::Field(id: 3)]
  @b : Int32

  @[MessagePack::Field(id: 1)]
  @c : Int32

  def initialize(@a, @b, @c)
  end
end

# ============ with ignore ==============================

struct CMessagePackAttr5
  include MessagePack::ArraySerializable

  @a : Int32

  @[MessagePack::Field(ignore: true)]
  @b = 9

  @c : Int32

  def initialize(@a, @b, @c)
  end
end

struct CMessagePackAttr6
  include MessagePack::ArraySerializable

  @[MessagePack::Field(id: 2)]
  @a : Int32

  @[MessagePack::Field(ignore: true)]
  @b = 9

  @[MessagePack::Field(id: 1)]
  @c : Int32

  def initialize(@a, @b, @c)
  end
end

struct CMessagePackAttr7
  include MessagePack::ArraySerializable

  @[MessagePack::Field(id: 2)]
  @a : Int32? = nil

  @[MessagePack::Field(ignore: true)]
  @b = 9

  @[MessagePack::Field(id: 1)]
  @c : Int32

  def initialize(@a, @b, @c)
  end
end

# ========== strict ===========

struct CMessagePackAttr8
  include MessagePack::ArraySerializable
  include MessagePack::ArraySerializable::Strict

  @a : Int32
  @b : Int32
  @c : Int32

  def initialize(@a, @b, @c)
  end
end

@[MessagePack::ArraySerializable::Options(variables: 8)]
struct CMessagePackAttr9
  include MessagePack::ArraySerializable
  include MessagePack::ArraySerializable::Strict

  @a : Int32
  @b : Int32

  @[MessagePack::Field(id: 7)]
  @c : Int32

  def initialize(@a, @b, @c)
  end
end

# ========== unmapped ===========

struct CMessagePackAttr10
  include MessagePack::ArraySerializable
  include MessagePack::ArraySerializable::Unmapped

  @a : Int32
  @b : Int32
  @c : Int32

  def initialize(@a, @b, @c)
  end
end

struct CMessagePackAttr11
  include MessagePack::ArraySerializable
  include MessagePack::ArraySerializable::Unmapped

  @[MessagePack::Field(id: 5)]
  @a : Int32

  @[MessagePack::Field(id: 1)]
  @b : Int32

  @[MessagePack::Field(id: 3)]
  @c : Int32

  def initialize(@a, @b, @c)
  end
end

struct CMessagePackAttr12
  include MessagePack::ArraySerializable
  include MessagePack::ArraySerializable::Unmapped

  @[MessagePack::Field(id: 5)]
  @a : Int32

  @[MessagePack::Field(ignore: true)]
  @b = 9

  @[MessagePack::Field(id: 3)]
  @c : Int32

  def initialize(@a, @b, @c)
  end
end

describe "MessagePack mapping" do
  it "CMessagePackAttr1" do
    CMessagePackAttr1.new(1, 2, 3).to_msgpack.should eq Bytes[147, 1, 2, 3]
    CMessagePackAttr1.from_msgpack(Bytes[147, 1, 2, 3]).should eq CMessagePackAttr1.new(1, 2, 3)
  end

  it "CMessagePackAttr1 raises when data shorter" do
    expect_raises(MessagePack::Error, "ArraySerializable(CMessagePackAttr1): expect array with 3 elements, but got 2 at 0") do
      CMessagePackAttr1.from_msgpack(Bytes[146, 1, 2])
    end
  end

  it "CMessagePackAttr1 raises when data not array" do
    expect_raises(MessagePack::Error, "ArraySerializable(CMessagePackAttr1): unpacker expect ArrayT type but got NullT at 0") do
      CMessagePackAttr1.from_msgpack(nil.to_msgpack)
    end
  end

  it "CMessagePackAttr1 raises when got nil for not nil variable" do
    expect_raises(MessagePack::Error, "Unexpected token NullT expected IntT at 2") do
      CMessagePackAttr1.from_msgpack(Bytes[147, 1, 192, 3])
    end
  end

  it "CMessagePackAttr1 allow to read after data end" do
    [CMessagePackAttr1.new(1, 2, 3), CMessagePackAttr1.new(3, 4, 5)].to_msgpack.should eq Bytes[146, 147, 1, 2, 3, 147, 3, 4, 5]
    Array(CMessagePackAttr1).from_msgpack(Bytes[146, 147, 1, 2, 3, 147, 3, 4, 5]).should eq [CMessagePackAttr1.new(1, 2, 3), CMessagePackAttr1.new(3, 4, 5)]
  end

  it "CMessagePackAttr1 allow to read after data end" do
    [CMessagePackAttr1.new(1, 2, 3), CMessagePackAttr1.new(3, 4, 5)].to_msgpack.should eq Bytes[146, 147, 1, 2, 3, 147, 3, 4, 5]
    Array(CMessagePackAttr1).from_msgpack(Bytes[146, 148, 1, 2, 3, 4, 148, 3, 4, 5, 6]).should eq [CMessagePackAttr1.new(1, 2, 3), CMessagePackAttr1.new(3, 4, 5)]
  end

  it "CMessagePackAttr2" do
    CMessagePackAttr2.new(1, 2, 3).to_msgpack.should eq Bytes[147, 3, 2, 1]
    CMessagePackAttr2.from_msgpack(Bytes[147, 3, 2, 1]).should eq CMessagePackAttr2.new(1, 2, 3)
  end

  it "CMessagePackAttr3" do
    CMessagePackAttr3.new(1, 2, 3).to_msgpack.should eq Bytes[150, 192, 3, 192, 2, 192, 1]
    CMessagePackAttr3.from_msgpack(Bytes[150, 192, 3, 192, 2, 192, 1]).should eq CMessagePackAttr3.new(1, 2, 3)
  end

  it "CMessagePackAttr3 ignore when other fields not nil" do
    CMessagePackAttr3.new(1, 2, 3).to_msgpack.should eq Bytes[150, 192, 3, 192, 2, 192, 1]
    CMessagePackAttr3.from_msgpack(Bytes[150, 1, 3, 1, 2, 1, 1]).should eq CMessagePackAttr3.new(1, 2, 3)
  end

  it "CMessagePackAttr4" do
    CMessagePackAttr4.new(1, 2, 3).to_msgpack.should eq Bytes[152, 192, 3, 192, 2, 192, 1, 192, 192]
    CMessagePackAttr4.from_msgpack(Bytes[152, 192, 3, 192, 2, 192, 1, 192, 192]).should eq CMessagePackAttr4.new(1, 2, 3)
  end

  it "CMessagePackAttr5" do
    CMessagePackAttr5.new(1, 2, 3).to_msgpack.should eq Bytes[146, 1, 3]
    CMessagePackAttr5.from_msgpack(Bytes[146, 1, 3]).should eq CMessagePackAttr5.new(1, 9, 3)
  end

  it "CMessagePackAttr6" do
    CMessagePackAttr6.new(1, 2, 3).to_msgpack.should eq Bytes[147, 192, 3, 1]
    CMessagePackAttr6.from_msgpack(Bytes[147, 192, 3, 1]).should eq CMessagePackAttr6.new(1, 9, 3)
  end

  it "CMessagePackAttr7" do
    CMessagePackAttr7.new(1, 2, 3).to_msgpack.should eq Bytes[147, 192, 3, 1]
    CMessagePackAttr7.from_msgpack(Bytes[147, 192, 3, 1]).should eq CMessagePackAttr7.new(1, 9, 3)
  end

  it "CMessagePackAttr7" do
    CMessagePackAttr7.new(nil, 2, 3).to_msgpack.should eq Bytes[147, 192, 3, 192]
    CMessagePackAttr7.from_msgpack(Bytes[147, 192, 3, 192]).should eq CMessagePackAttr7.new(nil, 9, 3)
  end

  it "CMessagePackAttr8" do
    CMessagePackAttr8.new(1, 2, 3).to_msgpack.should eq Bytes[147, 1, 2, 3]
    CMessagePackAttr8.from_msgpack(Bytes[147, 1, 2, 3]).should eq CMessagePackAttr8.new(1, 2, 3)
  end

  it "CMessagePackAttr8 raises when array is bigger" do
    expect_raises(MessagePack::Error, "got array(8) bigger than expected(3) at 0") do
      CMessagePackAttr8.from_msgpack(Bytes[152, 1, 2, 3, 2, 192, 1, 192, 192])
    end
  end

  it "CMessagePackAttr9" do
    CMessagePackAttr9.from_msgpack(Bytes[152, 1, 2, 3, 2, 192, 1, 192, 4]).should eq CMessagePackAttr9.new(1, 2, 4)
  end

  it "CMessagePackAttr9 raises when array is bigger" do
    expect_raises(MessagePack::Error, "got array(9) bigger than expected(8) at 0") do
      CMessagePackAttr9.from_msgpack(Bytes[153, 1, 2, 3, 2, 192, 1, 192, 4, 5])
    end
  end

  it "CMessagePackAttr10" do
    CMessagePackAttr10.new(1, 2, 3).to_msgpack.should eq Bytes[147, 1, 2, 3]
    s = CMessagePackAttr10.from_msgpack(Bytes[147, 1, 2, 3])
    s.should eq CMessagePackAttr10.new(1, 2, 3)
    s.msgpack_unmapped.size.should eq 0
  end

  it "CMessagePackAttr10 extra size" do
    s = CMessagePackAttr10.from_msgpack(Bytes[148, 1, 2, 3, 4])
    s.@b.should eq 2
    s.msgpack_unmapped.should eq({3 => 4_u8})
  end

  it "CMessagePackAttr11" do
    CMessagePackAttr11.new(1, 2, 3).to_msgpack.should eq Bytes[150, 192, 2, 192, 3, 192, 1]
    s = CMessagePackAttr11.from_msgpack(Bytes[150, 192, 2, 192, 3, 192, 1])
    s.should eq CMessagePackAttr11.new(1, 2, 3)
    s.msgpack_unmapped.size.should eq 0
  end

  it "CMessagePackAttr11 extra not nil fields" do
    s = CMessagePackAttr11.from_msgpack(Bytes[150, 7, 2, 8, 3, 9, 1])
    s.@b.should eq 2
    s.msgpack_unmapped.should eq({0 => 7_u8, 2 => 8_u8, 4 => 9_u8})
  end

  it "CMessagePackAttr11 extra size" do
    s = CMessagePackAttr11.from_msgpack(Bytes[152, 7, 2, 8, 3, 9, 1, 192, 10])
    s.@b.should eq 2
    s.msgpack_unmapped.should eq({0 => 7_u8, 2 => 8_u8, 4 => 9_u8, 7 => 10_u8})
  end

  it "CMessagePackAttr12" do
    CMessagePackAttr12.new(1, 2, 3).to_msgpack.should eq Bytes[150, 192, 192, 192, 3, 192, 1]
    s = CMessagePackAttr12.from_msgpack(Bytes[150, 192, 192, 192, 3, 192, 1])
    s.@b.should eq 9
    s.msgpack_unmapped.size.should eq 0
  end

  it "CMessagePackAttr12 extra not nil fields" do
    s = CMessagePackAttr12.from_msgpack(Bytes[150, 7, 2, 8, 3, 9, 1])
    s.@b.should eq 9
    s.msgpack_unmapped.should eq({0 => 7_u8, 1 => 2_u8, 2 => 8_u8, 4 => 9_u8})
  end

  it "CMessagePackAttr12 extra size" do
    s = CMessagePackAttr12.from_msgpack(Bytes[152, 7, 2, 8, 3, 9, 1, 192, 10])
    s.@b.should eq 9
    s.msgpack_unmapped.should eq({0 => 7_u8, 1 => 2_u8, 2 => 8_u8, 4 => 9_u8, 7 => 10_u8})
  end
end
