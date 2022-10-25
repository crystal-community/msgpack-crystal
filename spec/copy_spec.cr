require "./spec_helper"

def copy(x)
  io1 = IO::Memory.new
  x.to_msgpack(io1)
  io1.rewind

  io2 = IO::Memory.new
  c = MessagePack::Copy.new(io1, io2)
  c.copy_object

  io1.to_slice.should eq io2.to_slice
  io2.rewind
  y = typeof(x).from_msgpack(io2)

  x.should eq y
end

describe "MessagePack::Packer" do
  it { copy(1) }
  it { copy([1, 2, 3]) }
  it { copy({1 => 2, "bla" => "hah"}) }
  it { copy({"a": "jopa", "b": {1, 3, 4.6}, "c": ["a", 2, [3], {1 => 2}]}) }
  it { copy([1000000000] * 1000) }
  it { copy([[1], [[3]]]) }
  it { copy("asdf" * 1000) }
  it { copy(Int64[1, -1, 0x21, -0x21, 128, -128, -0x8000, 0x8000, 0xFFFF, -0xFFFF, -0x80000000, 0x80000000, -9223372036854775808, 9223372036854775807, 4294967295, -4294967295]) }
  it { copy("⬠ ⬡ ⬢ ⬣ ⬤ ⬥ ⬦") }
  it { copy(Bytes[1, 2, 3]) }
  it { copy([0.09937014424406129, -0.012362745428594163, -0.03641390471694943, -0.0445058835429372, 0.0]) }
  it { copy([0.09937014424406129, -0.012362745428594163, -0.03641390471694943, -0.0445058835429372, 0.0] * 10000) }
end
