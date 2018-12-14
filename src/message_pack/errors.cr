module MessagePack
  class Error < Exception; end

  # Raised on invalid MessagePack strings.
  class UnpackError < Error
    # The byte number where the invalid MessagePack was detected.
    getter byte_number : Int32

    # Creates a ParseException with the given message and byte number.
    def initialize(message, @byte_number = 0)
      super "#{message} at #{@byte_number}"
    end
  end

  class PackError < Error; end

  class UnexpectedByteError < UnpackError; end

  class TypeCastError < UnpackError; end

  class EofError < UnpackError
    def initialize(byte_number)
      super("Read after EOF", byte_number)
    end
  end
end
