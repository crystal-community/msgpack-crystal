# Raised on invalid MessagePack strings.
class MessagePack::UnpackException < MessagePack::Error
  # The line number where the invalid MessagePack was detected.
  getter byte_number : Int32

  # Creates a ParseException with the given message and byte number.
  def initialize(message, @byte_number = 0)
    super "#{message} at #{@byte_number}"
  end
end
