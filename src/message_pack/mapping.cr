module MessagePack
  # The `MessagePack.mapping` macro defines how an object is mapped to MessagePack.
  #
  # ### Example
  #
  # ```
  # require "msgpack"
  #
  # class Location
  #   MessagePack.mapping({
  #     lat: Float64,
  #     lng: Float64,
  #   })
  # end
  #
  # class House
  #   MessagePack.mapping({
  #     address:  String,
  #     location: {type: Location, nilable: true},
  #   })
  # end
  #
  # house = House.from_msgpack({"address" => "Crystal Road 1234", "location" => {"lat" => 12.3, "lng" => 34.5}}.to_msgpack)
  # house.address    # => "Crystal Road 1234"
  # house.location   # => #&lt;Location:0x10cd93d80 @lat=12.3, @lng=34.5>
  # house.to_msgpack # => %({"address":"Crystal Road 1234","location":{"lat":12.3,"lng":34.5}})
  # ```
  #
  # ### Usage
  #
  # `MessagePack.mapping` must receive a hash literal whose keys will define Crystal properties.
  #
  # The value of each key can be a single type (not a union type). Primitive types (numbers, string, boolean and nil)
  # are supported, as well as custom objects which use `MessagePack.mapping` or define a `new` method
  # that accepts a `MessagePack::Unpacker` and returns an object from it.
  #
  # The value can also be another hash literal with the following options:
  # * **type**: (required) the single type described above (you can use `MessagePack::Any` too)
  # * **key**: the property name in the MessagePack document (as opposed to the property name in the Crystal code)
  # * **nilable**: if true, the property can be `Nil`
  # * **default**: value to use if the property is missing in the MessagePack document, or if it's `null` and `nilable` was not set to `true`. If the default value creates a new instance of an object (for example `[1, 2, 3]` or `SomeObject.new`), a different instance will be used each time a MessagePack document is parsed.
  # * **converter**: specify an alternate type for parsing and generation. The converter must define `from_msgpack(MessagePack::Unpacker)` and `to_msgpack(value, MessagePack::Packer)` as class methods.
  #
  # The mapping also automatically defines Crystal properties (getters and setters) for each
  # of the keys. It doesn't define a constructor accepting those arguments, but you can provide
  # an overload.
  #
  # The macro basically defines a constructor accepting a `MessagePack::Unpacker` that reads from
  # it and initializes this type's instance variables. It also defines a `to_msgpack(MessagePack::Packer)` method
  # by invoking `to_msgpack(MessagePack::Packer)` on each of the properties (unless a converter is specified, in
  # which case `to_msgpack(value, MessagePack::Packer)` is invoked).
  #
  # This macro also declares instance variables of the types given in the mapping.
  #
  # If `strict` is true, unknown properties in the MessagePack
  # document will raise a parse exception. The default is `false`, so unknown properties
  # are silently ignored.
  macro mapping(properties, strict = false, emit_nulls = true)
    {% for key, value in properties %}
      {% properties[key] = {type: value} unless value.is_a?(HashLiteral) || value.is_a?(NamedTupleLiteral) %}
    {% end %}

    {% for key, value in properties %}
      @{{key.id}} : {{value[:type]}} {{ (value[:nilable] ? "?" : "").id }}

      {% if value[:setter] == nil ? true : value[:setter] %}
        def {{key.id}}=(_{{key.id}} : {{value[:type]}} {{ (value[:nilable] ? "?" : "").id }})
          @{{key.id}} = _{{key.id}}
        end
      {% end %}

      {% if value[:getter] == nil ? true : value[:getter] %}
        def {{key.id}}
          @{{key.id}}
        end
      {% end %}
    {% end %}

    def initialize(%pull : MessagePack::Unpacker)
      {% for key, value in properties %}
        %var{key.id} = nil
        %found{key.id} = false
      {% end %}

      token = %pull.current_token
      %pull.consume_hash do
        %key = Bytes.new(%pull)
        case %key
        {% for key, value in properties %}
          when {{value[:key] || key.id.stringify}}.to_slice
            %found{key.id} = true
            %var{key.id} =
              {% if value[:nilable] || value[:default] != nil %} %pull.read_nil_or do {% end %}

              {% if value[:converter] %}
                {{value[:converter]}}.from_msgpack(%pull)
              {% else %}
                {{value[:type]}}.new(%pull)
              {% end %}

            {% if value[:nilable] || value[:default] != nil %} end {% end %}
        {% end %}
        else
          {% if strict %}
            raise MessagePack::TypeCastError.new("Unknown msgpack attribute: #{String.new(%key)}", token.byte_number)
          {% else %}
            %pull.skip_value
          {% end %}
        end
      end

      {% for key, value in properties %}
        {% unless value[:nilable] || value[:default] != nil %}
          if %var{key.id}.is_a?(Nil) && !%found{key.id} && !Union({{value[:type]}}).nilable?
            raise MessagePack::TypeCastError.new("Missing msgpack attribute: {{(value[:key] || key).id}}")
          end
        {% end %}
      {% end %}

      {% for key, value in properties %}
        {% if value[:nilable] %}
          {% if value[:default] != nil %}
            @{{key.id}} = %found{key.id} ? %var{key.id} : {{value[:default]}}
          {% else %}
            @{{key.id}} = %var{key.id}
          {% end %}
        {% elsif value[:default] != nil %}
          @{{key.id}} = %var{key.id}.is_a?(Nil) ? {{value[:default]}} : %var{key.id}
        {% else %}
          @{{key.id}} = %var{key.id}.as({{value[:type]}})
        {% end %}
      {% end %}
    end

    def to_msgpack(packer : MessagePack::Packer)
      ready_fields = 0

      {% for key, value in properties %}
        _{{key.id}} = @{{key.id}}

        {% if emit_nulls %}
          ready_fields += 1
        {% else %}
          ready_fields += 1 unless _{{key.id}}.nil?
        {% end %}
      {% end %}

      packer.write_hash_start(ready_fields)

      {% for key, value in properties %}
        unless _{{key.id}}.nil?
          packer.write({{value[:key] || key.id.stringify}})
          {% if value[:converter] %}
            {{ value[:converter] }}.to_msgpack(_{{key.id}}, packer)
          {% else %}
            _{{key.id}}.to_msgpack(packer)
          {% end %}
        else
          {% if emit_nulls %}
            packer.write({{value[:key] || key.id.stringify}})
            nil.to_msgpack(packer)
          {% end %}
        end
      {% end %}
    end
  end
end
