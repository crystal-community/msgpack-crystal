require "./lexer"

module MessagePack
  # Fast copy msgpack objects from IO to IO, without full parse, without create temp objects
  # this is usefull for streaming apis
  # MessagePack::Copy.new(io1, io2).copy_objects(1)
  # This is from 40% to 700% faster than `MessagePack::IOUnpacker.new(io1).read.to_msgpack(io2)`
  struct Copy
    getter io_dst, io_src

    def initialize(@io_src : IO, @io_dst : IO)
    end

    def copy_objects(n = 1)
      n.times { copy_object }
    end

    def copy_object
      cb = next_byte
      @io_dst.write_byte(cb)
      copy_token(cb)
      1
    end

    protected def copy_token(current_byte : UInt8)
      case current_byte
      when 0xA0..0xBF
        copy(current_byte - 0xA0)
      when 0x80..0x8F
        copy_objects((current_byte - 0x80) * 2)
      when 0x90..0x9F
        copy_objects(current_byte - 0x90)
      when 0xC4, 0xD9
        size = read(UInt8)
        write_bytes(size)
        copy(size)
      when 0xC5, 0xDA
        size = read(UInt16)
        write_bytes(size)
        copy(size)
      when 0xC6, 0xDB
        size = read(UInt32)
        write_bytes(size)
        copy(size)
      when 0xC7
        size = read(UInt8)
        write_bytes(size)
        copy(size + 1)
      when 0xC8
        size = read(UInt16)
        write_bytes(size)
        copy(size + 1)
      when 0xC9
        size = read(UInt32)
        write_bytes(size)
        copy(size + 1)
      when 0xCC, 0xD0
        write_bytes(read(UInt8))
      when 0xCD, 0xD1
        write_bytes(read(UInt16))
      when 0xCE, 0xD2, 0xCA
        write_bytes(read(UInt32))
      when 0xCF, 0xD3, 0xCB
        write_bytes(read(UInt64))
      when 0xD4..0xD8
        size = 1 << (current_byte - 0xD4) # 1, 2, 4, 8, 16
        copy(size + 1)
      when 0xDC
        size = read UInt16
        write_bytes(size)
        copy_objects(size)
      when 0xDD
        size = read UInt32
        write_bytes(size)
        copy_objects(size)
      when 0xDE
        size = read UInt16
        write_bytes(size)
        copy_objects(size * 2)
      when 0xDF
        size = read UInt32
        write_bytes(size)
        copy_objects(size * 2)
        # else
        # just one byte copy
        # one bytes: 0xC0, 0xC2, 0xC3, 0xE0..0xFF, 0x00..0x7F
        # 0xC1 invalid symbol copied also, buy this is doesnot matter
      end
    end

    protected def next_byte : UInt8
      byte = @io_src.read_byte
      raise EofError.new(0) unless byte
      byte
    end

    def write_bytes(v)
      @io_dst.write_bytes(v, IO::ByteFormat::BigEndian)
    end

    def copy(size)
      IO.copy(@io_src, @io_dst, size)
    end

    protected def read(type : T.class) forall T
      @io_src.read_bytes(T, IO::ByteFormat::BigEndian)
    end
  end
end
