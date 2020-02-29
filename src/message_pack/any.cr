module MessagePack
  # A wrapper around a MessagePack object with convenience methods for type conversions
  struct Any
    getter raw : Type

    def initialize(@raw)
    end

    def dup
      Any.new @raw.dup
    end

    def clone
      Any.new @raw.clone
    end

    {% for name, type in {
                           nil:  Nil,
                           bool: Bool,
                           f:    Float64,
                           s:    String,
                           h:    Hash(Type, Type),
                           a:    Array(Type),
                         } %}
      # Convert to {{ type }}
      def as_{{ name }} : {{ type }}
        if @raw.is_a?({{type}})
          @raw.as {{ type }}
        else
          raise TypeCastError.new("Cannot cast #{@raw.class} to {{ type }}")
        end
      end

      # Maybe convert to {{ type }}?
      def as_{{ name }}? : {{ type }}?
        @raw.as? {{ type }}
      end
    {% end %}

    {% for size in {8, 16, 32, 64} %}
      {% for sign, type_prefix in {i: "Int", u: "UInt"} %}
        {% name = "#{sign}#{size}".id %}
        {% type = "#{type_prefix.id}#{size}".id %}
        # Convert to {{ type }}
        def as_{{ name }} : {{ type }}
          %raw = @raw
          return {{ type }}.new(%raw) if %raw.responds_to? :to_{{ name }}
          raise TypeCastError.new("Cannot cast #{@raw.class} to {{ type }}")
        end

        # Maybe convert to {{ type }}?
        def as_{{ name }}? : {{ type }}?
          %raw = @raw
          return {{ type }}.new(%raw) if %raw.responds_to? :to_{{ name }}
          nil
        end
      {% end %}
    {% end %}

    def as_i
      as_i32
    end

    def as_i?
      as_i32?
    end

    def as_u
      as_u32
    end

    def as_u?
      as_u32?
    end

    def [](key : Symbol) : Any
      self[key.to_s.as(Type)]
    end

    def [](key : Type) : Any
      if (index = key.as?(Int)) && (arr = @raw.as? Array(Type))
        return Any.new(arr[index])
      elsif hash = @raw.as? Hash(Type, Type)
        return Any.new hash[key]
      else
        raise TypeCastError.new("Expected Array or Hash for #[], not #{@raw.class}")
      end
    end

    def []?(key : Type) : Any?
      if (index = key.as?(Int)) && (arr = @raw.as? Array(Type))
        value = arr[index]?
        Any.new arr.fetch(index) { return nil }
      elsif hash = @raw.as? Hash(Type, Type)
        value = hash[key]?
        unless value.nil?
          return Any.new value
        end
      else
        raise TypeCastError.new("Expected Array or Hash for #[]?, not #{@raw.class}")
      end
    end

    def each
      if arr = @raw.as? Array(Type)
        arr.each do |a|
          yield Any.new(a)
        end
      elsif hash = @raw.as? Hash(Type, Type)
        hash.each do |k, v|
          yield({Any.new(k), Any.new(v)})
        end
      else
        raise TypeCastError.new("Expected Array or Hash for #each, not #{@raw.class}")
      end
    end

    def size
      r = @raw
      case r
      when Hash(Type, Type), Array(Type)
        return r.size
      else
        raise TypeCastError.new("Expected Array or Hash for #each, not #{@raw.class}")
      end
    end

    def dig?(key : Type, *subkeys)
      if (value = self[key]?) && value.responds_to?(:dig?)
        value.dig?(*subkeys)
      end
    end

    # :nodoc:
    def dig?(key : Type)
      self[key]?
    end

    def dig(key : Type, *subkeys)
      if (value = self[key]) && value.responds_to?(:dig)
        return value.dig(*subkeys)
      end
      raise TypeCastError.new("MessagePack::Any value not diggable for key: #{key.inspect}")
    end

    def dig(key : Type)
      self[key]
    end

    delegate to_s, inspect, :==, to: @raw
    forward_missing_to @raw
  end
end

class Object
  def ===(other : MessagePack::Any)
    self === other.raw
  end
end

class Regex
  def ===(other : MessagePack::Any)
    value = self === other.raw
    $~ = $~
    value
  end
end
