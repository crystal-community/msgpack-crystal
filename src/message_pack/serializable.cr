module MessagePack
  annotation Field
  end

  # The `MessagePack::Serializable` module automatically generates methods for MessagePack serialization when included.
  #
  # ### Example
  #
  # ```
  # require "msgpack"
  #
  # class Location
  #   include MessagePack::Serializable
  #
  #   @[MessagePack::Field(key: "lat")]
  #   property latitude : Float64
  #
  #   @[MessagePack::Field(key: "lng")]
  #   property longitude : Float64
  # end
  #
  # class House
  #   include MessagePack::Serializable
  #   property address : String
  #   property location : Location?
  # end
  #
  # house = House.from_msgpack({address: "Crystal Road 1234", location: {"lat": 12.3, "lng": 34.5}}.to_msgpack)
  # house.address    # => "Crystal Road 1234"
  # house.location   # => #<Location:0x10cd93d80 @latitude=12.3, @longitude=34.5>
  # house.to_msgpack # => Bytes[130, 167, 97, 100, 100, 114, 101, 115, ...
  #
  # houses = Array(House).from_msgpack([{address: "Crystal Road 1234", location: {"lat": 12.3, "lng": 34.5}}].to_msgpack)
  # houses.size       # => 1
  # houses.to_msgpack # => Bytes[145, 130, 167, 97, 100, 100, 114, 101, ...
  # ```
  #
  # ### Usage
  #
  # Including `MessagePack::Serializable` will create `#to_msgpack` and `self.from_msgpack` methods on the current class,
  # and a constructor which takes a `MessagePack::PullParser`. By default, these methods serialize into a msgpack
  # object containing the value of every instance variable, the keys being the instance variable name.
  # Most primitives and collections supported as instance variable values (string, integer, array, hash, etc.),
  # along with objects which define to_msgpack and a constructor taking a `MessagePack::PullParser`.
  # Union types are also supported, including unions with nil. If multiple types in a union parse correctly,
  # it is undefined which one will be chosen.
  #
  # To change how individual instance variables are parsed and serialized, the annotation `MessagePack::Field`
  # can be placed on the instance variable. Annotating property, getter and setter macros is also allowed.
  # ```
  # class A
  #   include MessagePack::Serializable
  #
  #   @[MessagePack::Field(key: "my_key", emit_null: true)]
  #   getter a : Int32?
  # end
  # ```
  #
  # `MessagePack::Field` properties:
  # * **ignore**: if `true` skip this field in seriazation and deserialization (by default false)
  # * **key**: the value of the key in the msgpack object (by default the name of the instance variable)
  # * **root**: assume the value is inside a MessagePack object with a given key (see `Object.from_msgpack(string_or_io, root)`)
  # * **converter**: specify an alternate type for parsing and generation. The converter must define `from_msgpack(MessagePack::PullParser)` and `to_msgpack(value, MessagePack::Builder)` as class methods. Examples of converters are `Time::Format` and `Time::EpochConverter` for `Time`.
  # * **presense**: if `true`, a `@{{key}}_present` instance variable will be generated when the key was present (even if it has a `null` value), `false` by default
  # * **emit_null**: if `true`, emits a `null` value for nilable property (by default nulls are not emitted)
  #
  # Deserialization also respects default values of variables:
  # ```
  # struct A
  #   include MessagePack::Serializable
  #   @a : Int32
  #   @b : Float64 = 1.0
  # end
  #
  # A.from_msgpack({a: 1}.to_msgpack) # => A(@a=1, @b=1.0)
  # ```
  #
  # ### Extensions: `MessagePack::Serializable::Strict` and `MessagePack::Serializable::Unmapped`.
  #
  # If the `MessagePack::Serializable::Strict` module is included, unknown properties in the MessagePack
  # document will raise a parse exception. By default the unknown properties
  # are silently ignored.
  # If the `MessagePack::Serializable::Unmapped` module is included, unknown properties in the MessagePack
  # document will be stored in a `Hash(String, MessagePack::Any)`. On serialization, any keys inside msgpack_unmapped
  # will be serialized appended to the current msgpack object.
  # ```
  # struct A
  #   include MessagePack::Serializable
  #   include MessagePack::Serializable::Unmapped
  #   @a : Int32
  # end
  #
  # a = A.from_msgpack({a: 1, b: 2}.to_msgpack)                # => A(@msgpack_unmapped={"b" => 2_i64}, @a=1)
  # Hash(String, MessagePack::Type).from_msgpack(a.to_msgpack) # => {"a" => 1_u8, "b" => 2_u8}
  # ```
  #
  #
  # ### Class annotation `MessagePack::Serializable::Options`
  #
  # supported properties:
  # * **emit_nulls**: if `true`, emits a `null` value for all nilable properties (by default nulls are not emitted)
  #
  # ```
  # @[MessagePack::Serializable::Options(emit_nulls: true)]
  # class A
  #   include MessagePack::Serializable
  #   @a : Int32?
  # end
  # ```
  module Serializable
    annotation Options
    end

    macro included
      def self.new(pull : ::MessagePack::Unpacker)
        instance = allocate
        instance.initialize(pull, nil)
        GC.add_finalizer(instance) if instance.responds_to?(:finalize)
        instance
      end

      macro inherited
        def self.new(pull : ::MessagePack::Unpacker)
          super
        end
      end
    end

    def initialize(pull : ::MessagePack::Unpacker, dummy : Nil)
      {% begin %}
        {% properties = {} of Nil => Nil %}
        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(::MessagePack::Field) %}
          {% unless ann && ann[:ignore] %}
            {%
              properties[ivar.id] = {
                type:        ivar.type,
                key:         ((ann && ann[:key]) || ivar).id.stringify,
                has_default: ivar.has_default_value?,
                default:     ivar.default_value,
                nilable:     ivar.type.nilable?,
                converter:   ann && ann[:converter],
                presence:    ann && ann[:presence],
              }
            %}
          {% end %}
        {% end %}

        {% for name, value in properties %}
          %var{name} = nil
          %found{name} = false
        {% end %}

        pull.read_hash(false) do
          key = Bytes.new(pull)
          {% if properties.size > 0 %}
            case key
            {% for name, value in properties %}
              when {{value[:key]}}.to_slice
                %found{name} = true
                %var{name} =
                  {% if value[:nilable] || value[:has_default] %} pull.read_nil_or { {% end %}

                  {% if value[:converter] %}
                    {{value[:converter]}}.from_msgpack(pull)
                  {% else %}
                    ::Union({{value[:type]}}).new(pull)
                  {% end %}

                  {% if value[:nilable] || value[:has_default] %} } {% end %}
            {% end %}
            else
              on_unknown_msgpack_attribute(pull, String.new(key))
            end
          {% else %}
            on_unknown_msgpack_attribute(pull, String.new(key))
          {% end %}
        end

        {% for name, value in properties %}
          {% unless value[:nilable] || value[:has_default] %}
            if %var{name}.nil? && !%found{name} && !::Union({{value[:type]}}).nilable?
              raise ::MessagePack::UnpackException.new("Missing msgpack attribute: {{value[:key].id}}")
            end
          {% end %}

          {% if value[:nilable] %}
            {% if value[:has_default] != nil %}
              @{{name}} = %found{name} ? %var{name} : {{value[:default]}}
            {% else %}
              @{{name}} = %var{name}
            {% end %}
          {% elsif value[:has_default] %}
            @{{name}} = %var{name}.nil? ? {{value[:default]}} : %var{name}
          {% else %}
            @{{name}} = (%var{name}).as({{value[:type]}})
          {% end %}

          {% if value[:presence] %}
            @{{name}}_present = %found{name}
          {% end %}
        {% end %}
      {% end %}
      after_initialize
    end

    protected def after_initialize
    end

    protected def on_unknown_msgpack_attribute(pull, key)
      pull.skip_value
    end

    protected def additional_write_fields_count
      0
    end

    protected def on_to_msgpack(packer : ::MessagePack::Packer)
    end

    def to_msgpack(packer : ::MessagePack::Packer)
      {% begin %}
        {% options = @type.annotation(::MessagePack::Serializable::Options) %}
        {% emit_nulls = options && options[:emit_nulls] %}

        {% properties = {} of Nil => Nil %}
        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(::MessagePack::Field) %}
          {% unless ann && ann[:ignore] %}
            {%
              properties[ivar.id] = {
                type:      ivar.type,
                key:       ((ann && ann[:key]) || ivar).id.stringify,
                converter: ann && ann[:converter],
                emit_null: (ann && (ann[:emit_null] != nil) ? ann[:emit_null] : emit_nulls),
              }
            %}
          {% end %}
        {% end %}

        ready_fields = additional_write_fields_count

        {% for name, value in properties %}
          _{{name}} = @{{name}}

          {% if value[:emit_null] %}
            ready_fields += 1
          {% else %}
            ready_fields += 1 unless _{{name}}.nil?
          {% end %}
        {% end %}

        packer.write_hash_start(ready_fields)

        {% for name, value in properties %}
          unless _{{name}}.nil?
            packer.write({{value[:key]}})
            {% if value[:converter] %}
              {{ value[:converter] }}.to_msgpack(_{{name}}, packer)
            {% else %}
              _{{name}}.to_msgpack(packer)
            {% end %}
          else
            {% if value[:emit_null] %}
              packer.write({{value[:key]}})
              nil.to_msgpack(packer)
            {% end %}
          end
        {% end %}

        on_to_msgpack(packer)

      {% end %}
    end

    module Strict
      protected def on_unknown_msgpack_attribute(pull, key)
        raise ::MessagePack::UnpackException.new("Unknown msgpack attribute: #{key}")
      end
    end

    module Unmapped
      @[MessagePack::Field(ignore: true)]
      property msgpack_unmapped = Hash(String, ::MessagePack::Type).new

      protected def on_unknown_msgpack_attribute(pull, key)
        msgpack_unmapped[key] = pull.read
      end

      protected def additional_write_fields_count
        msgpack_unmapped.size
      end

      protected def on_to_msgpack(packer)
        msgpack_unmapped.each do |key, value|
          key.to_msgpack(packer)
          value.to_msgpack(packer)
        end
      end
    end
  end
end
