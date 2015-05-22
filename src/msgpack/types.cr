lib LibMsgpack

  union Int16
    value : ::Int16
    byte_array : ::UInt8[2]
  end

  union Int32
    value : ::Int32
    byte_array : ::UInt8[4]
  end

  union Int64
    value : ::Int64
    byte_array : ::UInt8[8]
  end

  union UInt8
    value : ::UInt8
    byte_array : ::UInt8[1]
  end

  union UInt16
    value : ::UInt16
    byte_array : ::UInt8[2]
  end

  union UInt32
    value : ::UInt32
    byte_array : ::UInt8[4]
  end

  union UInt64
    value : ::UInt64
    byte_array : ::UInt8[8]
  end

  union Double
    value : ::Float64
    byte_array : ::UInt8[8]
  end

  union Float
    value : ::Float32
    byte_array : ::UInt8[4]
  end
end
