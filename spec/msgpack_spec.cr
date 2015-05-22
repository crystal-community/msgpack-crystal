require "./spec_helper"

struct TestCase
    property description
    property unpacked
    property packed

    def initialize(@description, @unpacked, @packed : (Array(Int) | String))
    end
end

describe Msgpack do
    key = {"x" => {"y" => "z"}}
    hash_of_hashes = {key => "s"}

    tests = {
        "constant values" => [
            TestCase.new("nil", nil, [0xC0u8]),
            TestCase.new("false", false, [0xC2u8]),
            TestCase.new("true", true, [0xC3u8]),
        ],
        "numbers" => [
            TestCase.new("zero", 0, [0x00]),
            TestCase.new("fix num", 127, [0x7f]),
            TestCase.new("small integers", 128, [0xcc, 0x80]),
            TestCase.new("medium integers", 256, [0xcd, 0x01, 0x00]),
            TestCase.new("large integers", 2**31 - 1, [0xce, 0x7f, 0xff, 0xff, 0xff])
            TestCase.new("huge integers", 2**64 - 1, [0xcf,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff]),
            TestCase.new("-1", -1, [0xff]),
            TestCase.new("-33", -33, [0xd0,0xdf]),
            TestCase.new("-129", -129, [0xd1,0xff,0x7f]),
            TestCase.new("-8444910", -8444910, [0xd2,0xff,0x7f,0x24,0x12]),
            TestCase.new("-41957882392009710", -41957882392009710, [0xd3,0xff,0x6a,0xef,0x87,0x3c,0x7f,0x24,0x12]),
            TestCase.new("negative integers", -1, [0xff]),
            TestCase.new("1.0", 1.0, [0xcb,0x3f,0xf0,0x00,0x00,0x00,0x00,0x00,0x00]),
            TestCase.new("small floats", 3.14, [203, 64, 9, 30, 184, 81, 235, 133, 31]),
            TestCase.new("big floats", Math::PI * 1_000_000_000_000_000_000, [203, 67, 197, 204, 150, 239, 209, 25, 37]),
            TestCase.new("negative floats", -2.1, [0xcb,0xc0,0x00,0xcc,0xcc,0xcc,0xcc,0xcc,0xcd])
        ],
        "strings" => [
            TestCase.new("strings", "hello world", [0xAB] + "hello world".bytes),
            TestCase.new("empty strings", "", [0xA0]),
            TestCase.new("medium strings", "x" * 0xdd, [0xD9,0xDD] + ("x" * 0xDD).bytes),
            TestCase.new("big strings", "x" * 0xdddd, [0xDA, 0xDD, 0xDD] + ("x" * 0xdddd).bytes),
            TestCase.new("huge strings", "x" * 0x0000dddd, [0xDB, 0x00, 0x00, 0xDD,0xDD] + ("x" * 0x0000dddd).bytes),
        ],
        "binaries" => [
            TestCase.new("medium binary", "\a" * 0x5, [0xc4,0x05] + ("\a" * 0x5).bytes),
            TestCase.new("big binary", "\a" * 0x100, [0xc5,0x01,0x00] + ("\a" * 0x100).bytes),
            TestCase.new("huge binary", "\a" * 0x10000, [0xc6, 0x00, 0x01, 0x00, 0x00] + ("\a" * 0x10000).bytes),
        ],
        "arrays" => [
            TestCase.new("empty arrays", [] of String, [0x90]),
            TestCase.new("small arrays", [1, 2], [0x92, 0x01, 0x02]),
            TestCase.new("medium arrays", Array.new(0x111, false), [0xdc, 0x01, 0x11] + Array.new(0x111, 0xc2)),
            TestCase.new("big arrays", Array.new(0x11111, false), [0xdd, 0x00, 0x01, 0x11, 0x11] + Array.new(0x11111, 0xc2)),
            TestCase.new("arrays with strings", ["hello", "world"], [0x92, 0xa5] + "hello".bytes + [0xa5] + "world".bytes),
            TestCase.new("arrays with mixed values", ["hello", "world", 42], [0x93, 0xa5]+ "hello".bytes + [0xa5] + "world*".bytes),
            TestCase.new("arrays of arrays", [[[[1, 2], 3], 4]], [0x91, 0x92, 0x92, 0x92, 0x01, 0x02, 0x03, 0x04]),
        ]
        "hashes" => [
            TestCase.new("empty hashes", Hash(String,String).new, [0x80])
            TestCase.new("small hashes", {"foo" => "bar"}, [0x81,0xa3] + "foo".bytes + [0xa3] + "bar".bytes),
            TestCase.new("medium hashes", {"foo" => "bar"}, [0xde, 0x00, 0x01, 0xa3] + "foo".bytes + [0xa3] + "bar".bytes),
            TestCase.new("big hashes", {"foo" => "bar"}, [0xdf, 0x00, 0x00, 0x00, 0x01, 0xa3] + "foo".bytes + [0xa3] + "bar".bytes),
            TestCase.new("hashes with mixed keys and values", {"foo" => "bar", 3 => "three", "four" => 4, "x" => ["y"], "a" => "b"}, [0x85,0xa3] + "foo".bytes + [0xa3] + "bar".bytes + [0x03,0xa5] + "three".bytes + [0xa4] + "four".bytes + [0x04, 0xa1] + "x".bytes + [0x91, 0xa1] + "y".bytes + [0xa1] + "a".bytes + [0xa1] + "b".bytes),
            TestCase.new("hashes of hashes", hash_of_hashes, [0x81, 0x81, 0xa1] + "x".bytes + [0x81, 0xa1] + "y".bytes + [0xa1] + "z".bytes + [0xa1] + "s".bytes)
            TestCase.new("hashes with nils", {"foo" => nil}, [0x81, 0xa3] + "foo".bytes + [0xc0])
          ]

    }

    tests.each do |context, test_cases|
        test_cases.each do |test_case|
            it "#{context}: unpacks #{test_case.description}" do
                Msgpack.unpack(test_case.packed).should eq(test_case.unpacked)
            end
        end
    end

end
