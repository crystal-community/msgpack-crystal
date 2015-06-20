# require "./spec_helper"
#
# class MessagePack::PullParser
#   def assert(event_kind : Symbol)
#     kind.should eq(event_kind)
#     read_next
#   end
#
#   def assert(value : Nil)
#     kind.should eq(:nil)
#     read_next
#   end
#
#   def assert(value : (UInt8 | UInt16 | UInt32 | UInt64))
#     kind.should eq(:uint)
#     uint_value.should eq(value)
#     read_next
#   end
#
#   def assert(value : (Int8 | Int16 | Int32 | Int64))
#     kind.should eq(:int)
#     int_value.should eq(value)
#     read_next
#   end
#
#   def assert(value : (Float32 | Float64))
#     kind.should eq(:float)
#     float_value.should eq(value)
#     read_next
#   end
#
#   def assert(value : Bool)
#     kind.should eq(:bool)
#     bool_value.should eq(value)
#     read_next
#   end
#
#   def assert(value : String)
#     kind.should eq(:string)
#     string_value.should eq(value)
#     read_next
#   end
#
#   def assert(array : Array)
#     assert_array do
#       array.each do |x|
#         assert x
#       end
#     end
#   end
#
#   def assert(value : Hash)
#   end
#
#   def assert_array
#     kind.should eq(:ARRAY)
#     read_next
#     yield
#     read_next
#   end
#
#   def assert_array
#     assert_array {}
#   end
# end
#
# private def assert_pull_parse(type, bytes, file = __FILE__, line = __LINE__)
#   slice = Slice(UInt8).new(bytes.buffer, bytes.length)
#   it "parses #{type}", file, line do
#     parser = MessagePack::PullParser.new SliceIO(UInt8).new(slice)
#     parser.assert MessagePack.parse(SliceIO(UInt8).new(slice))
#     parser.kind.should eq(:EOF)
#   end
# end
#
# describe "MessagePack::PullParser" do
#   assert_pull_parse("nil", UInt8[0xC0])
#   assert_pull_parse("false", UInt8[0xC2])
#   assert_pull_parse("true", UInt8[0xC3])
#   assert_pull_parse("1", UInt8[0x00])
#   assert_pull_parse("-1", UInt8[0xff])
#   assert_pull_parse("1.0", UInt8[0xcb,0x3f,0xf0,0x00,0x00,0x00,0x00,0x00,0x00])
#   assert_pull_parse("big floats", UInt8[203, 67, 197, 204, 150, 239, 209, 25, 37])
#   assert_pull_parse("hello world", UInt8[0xAB] + "hello world".bytes)
#   assert_pull_parse("", UInt8[0xA0])
#   assert_pull_parse("medium binary", UInt8[0xc4,0x05] + ("\a" * 0x5).bytes)
#   assert_pull_parse("[]", UInt8[0x90])
#   assert_pull_parse("[1,2]", UInt8[0x92, 0x01, 0x02])
#   assert_pull_parse("{}", UInt8[0x80])
#   assert_pull_parse(%("foo" => "bar"), UInt8[0x81,0xa3] + "foo".bytes + UInt8[0xa3] + "bar".bytes)
# end
