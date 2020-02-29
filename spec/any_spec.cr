require "./spec_helper"

def as_any(obj)
  MessagePack.unpack(obj.to_msgpack)
end

describe MessagePack::Any do
  it "parses from bytes" do
    MessagePack::Any.from_msgpack(1.to_msgpack).as_i.should eq 1
  end

  describe "casts" do
    it "raises TypeCastError" do
      expect_raises(MessagePack::TypeCastError, "Cannot cast String to Nil") do
        as_any("bla").as_nil
      end
    end

    it "gets nil" do
      as_any(nil).as_nil.should be_nil
    end

    it "gets bool" do
      as_any(true).as_bool.should be_true
      as_any(false).as_bool.should be_false
      as_any(true).as_bool?.should be_true
      as_any(false).as_bool?.should be_false
      as_any(2).as_bool?.should be_nil
    end

    it "gets int32" do
      as_any(123).as_i32.should eq(123)
      as_any(123).as_i.should eq(123)
      as_any(123).as_i32?.should eq(123)
      as_any(123).as_i?.should eq(123)
      as_any(true).as_i32?.should be_nil
    end

    it "gets int64" do
      as_any(123456789123456).as_i64.should eq(123456789123456)
      as_any(123456789123456).as_i64?.should eq(123456789123456)
      as_any(true).as_i64?.should be_nil
    end

    it "gets float32" do
      as_any(123.45).as_f.should eq(123.45)
      as_any(123.45).as_f?.should eq(123.45)
      as_any(true).as_f?.should be_nil
    end

    it "gets float64" do
      as_any(123.45).as_f.should eq(123.45)
      as_any(123.45).as_f?.should eq(123.45)
      as_any(true).as_f?.should be_nil
    end

    it "gets string" do
      as_any("hello").as_s.should eq("hello")
      as_any("hello").as_s?.should eq("hello")
      as_any(true).as_s?.should be_nil
    end

    it "gets array" do
      as_any([1, 2, 3]).as_a.should eq([1, 2, 3])
      as_any([1, 2, 3]).as_a?.should eq([1, 2, 3])
      as_any(true).as_a?.should be_nil
    end

    it "gets hash" do
      as_any({"foo" => "bar"}).as_h.should eq({"foo" => "bar"})
      as_any({"foo" => "bar"}).as_h?.should eq({"foo" => "bar"})
      as_any(true).as_h?.should be_nil
    end
  end

  describe "#size" do
    it "of array" do
      as_any([1, 2, 3]).size.should eq(3)
    end

    it "of hash" do
      as_any({"foo" => "bar"}).size.should eq(1)
    end
  end

  describe "#each" do
    it "of array" do
      res = ""
      as_any([1, 2, 3]).each { |v| res += "#{v}," }
      res.should eq "1,2,3,"
    end

    it "of hash" do
      res = ""
      as_any({"foo" => "bar", 1 => nil}).each { |(k, v)| res += "#{k}-#{v}," }
      res.should eq "foo-bar,1-,"
    end
  end

  describe "#[]" do
    it "of array" do
      as_any([1, 2, 3])[1].raw.should eq(2)
    end

    it "of hash" do
      as_any({"foo": "bar"})["foo"].raw.should eq("bar")
    end
  end

  describe "#[]?" do
    it "of array" do
      as_any([1, 2, 3])[1]?.not_nil!.raw.should eq(2)
      as_any([1, 2, 3])[3]?.should be_nil
      as_any([true, false])[1]?.should eq false
    end

    it "of hash" do
      as_any({"foo" => "bar"})["foo"]?.not_nil!.raw.should eq("bar")
      as_any({"foo" => "bar"})["fox"]?.should be_nil
      as_any({"foo" => false})["foo"]?.should eq false
    end
  end

  describe "#dig?" do
    it "gets the value at given path given splat" do
      obj = as_any({"foo" => [1, {"bar" => [2, 3]}]})

      obj.dig?("foo", 0).should eq(1)
      obj.dig?("foo", 1, "bar", 1).should eq(3)
    end

    it "returns nil if not found" do
      obj = as_any({"foo": [1, {"bar": [2, 3]}]})

      obj.dig?("foo", 10).should be_nil
      obj.dig?("bar", "baz").should be_nil
      obj.dig?("").should be_nil
    end
  end

  describe "dig" do
    it "gets the value at given path given splat" do
      obj = as_any({"foo": [1, {"bar": [2, 3]}]})

      obj.dig("foo", 0).should eq(1)
      obj.dig("foo", 1, "bar", 1).should eq(3)
    end

    it "raises if not found" do
      obj = as_any({"foo" => [1, {"bar" => [2, 3]}]})

      expect_raises Exception, %(Expected Array or Hash for #[], not Array(MessagePack::Type)) do
        obj.dig("foo", 1, "bar", "baz")
      end
      expect_raises KeyError, %(Missing hash key: "z") do
        obj.dig("z")
      end
      expect_raises KeyError, %(Missing hash key: "") do
        obj.dig("")
      end
    end
  end

  it "traverses big structure" do
    obj = as_any({"foo" => [1, {"bar": [2, 3]}]})
    obj["foo"][1]["bar"][1].as_i32.should eq(3)
  end

  it "compares to other objects" do
    obj = as_any([1, 2])
    obj.should eq([1, 2])
    obj[0].should eq(1)
  end

  it "can compare with ===" do
    (1 === as_any(1)).should be_truthy
  end

  it "exposes $~ when doing Regex#===" do
    (/o+/ === as_any("foo")).should be_truthy
    $~[0].should eq("oo")
  end

  context "to_msgpack" do
    it "int" do
      MessagePack::Any.from_msgpack(1.to_msgpack).to_msgpack.should eq Bytes[1]
    end

    it "int" do
      b = [nil, 1, "bla"].to_msgpack
      a = MessagePack::Any.from_msgpack(b)
      a.as_a.size.should eq 3
      a.to_msgpack.should eq b
    end
  end
end
