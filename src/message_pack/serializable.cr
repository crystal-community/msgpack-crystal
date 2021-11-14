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
  # Including `MessagePack::Serializable` will create `#to_msgpack` and `self.from_msgpack` methods on the current object,
  # and a constructor which accepts a `MessagePack::Unpacker`. By default, the object serializes into a msgpack
  # object containing values of every instance variable, with keys equal to the variable name.
  # Most primitives and collections supported as instance variable values (`String`, `Number`, `Array`, `Hash` etc.),
  # along with objects which define `#to_msgpack` and a constructor accepting a `MessagePack::Unpacker`.
  # Union types are also supported, including unions with `nil`. If multiple types in a union parse correctly,
  # it is undefined which one will be chosen.
  #
  # To change how individual instance variables are parsed and serialized, the annotation `MessagePack::Field`
  # can be applied to an instance variable. Annotating property, getter and setter macros is also allowed.
  #
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
  #
  # * **ignore**: skip this field on seriazation and deserialization if **ignore** is `true`
  # * **key**: value of the key in the msgpack object (the name of the instance variable by default)
  # * **root**: assume that the value is inside a MessagePack object with a given key (see `Object.from_msgpack(string_or_io, root)`)
  # * **converter**: specify an alternate type for parsing and generation. The converter must define `.from_msgpack(MessagePack::Unpacker)` and `.to_msgpack(value, MessagePack::Packer)` as class methods. Example converters are `Time::Format` and `Time::EpochConverter`
  # * **emit_null**: emit Null value for this field if it is `nil` and *emit_null* is `true`. Nulls are not emitted by default
  #
  # Deserialization also respects default values of variables:
  #
  # ```
  # struct A
  #   include MessagePack::Serializable
  #
  #   @a : Int32
  #   @b : Float64 = 1.0
  # end
  #
  # A.from_msgpack({a: 1}.to_msgpack) # => A(@a=1, @b=1.0)
  # ```
  #
  # ### Extensions: `MessagePack::Serializable::Strict`, `MessagePack::Serializable::Unmapped` and `MessagePack::Serializable::Presence`.
  #
  # If the `MessagePack::Serializable::Strict` module is included, then unknown properties in a msgpack
  # object would raise a parse exception on deserialization. Unknown properties are silently ignored by default.
  #
  # If the `MessagePack::Serializable::Unmapped` module is included, then all unknown properties in a msgpack
  # object would be put into the `@msgpack_unmapped : Hash(String, MessagePack::Any)` variable.
  # Upon serialization, all keys inside `@msgpack_unmapped` would be serialized and appended to the current msgpack object.
  #
  # ```
  # struct A
  #   include MessagePack::Serializable
  #   include MessagePack::Serializable::Unmapped
  #
  #   @a : Int32
  # end
  #
  # a = A.from_msgpack({a: 1, b: 2}.to_msgpack)                # => A(@msgpack_unmapped={"b" => 2_i64}, @a=1)
  # Hash(String, MessagePack::Type).from_msgpack(a.to_msgpack) # => {"a" => 1_u8, "b" => 2_u8}
  # ```
  #
  # If the `MessagePack::Serializable::Presence` module is included, then the method `#key_present?` is defined,
  # which allows to check if a key is present in the original msgpack object.
  #
  # ```
  # struct A
  #   include MessagePack::Serializable
  #   include MessagePack::Serializable::Presence
  #
  #   @a : Int32?
  # end
  #
  # A.from_msgpack({a: 1}.to_msgpack).key_present?(:a) # => true
  # A.from_msgpack({b: 1}.to_msgpack).key_present?(:a) # => false
  # ```
  #
  # ### Class annotation `MessagePack::Serializable::Options`
  #
  # supported properties:
  # * **emit_nulls**: emit Null value for nilable instance variables if *emit_null* is `true`. Nulls are not emitted by default
  #
  # ```
  # @[MessagePack::Serializable::Options(emit_nulls: true)]
  # class A
  #   include MessagePack::Serializable
  #
  #   @a : Int32?
  # end
  # ```
  module Serializable
    annotation Options
    end

    macro included
      def self.new(pull : ::MessagePack::Unpacker)
        instance = allocate
        instance.initialize(__pull_for_msgpack_serializable: pull)
        GC.add_finalizer(instance) if instance.responds_to?(:finalize)
        instance
      end

      macro inherited
        def self.new(pull : ::MessagePack::Unpacker)
          super
        end
      end
    end

    def initialize(*, __pull_for_msgpack_serializable pull : ::MessagePack::Unpacker)
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
              }
            %}
          {% end %}
        {% end %}

        {% for name, value in properties %}
          %var{name} = nil
          %found{name} = nil
        {% end %}

        token = pull.current_token
        pull.consume_hash do
          %key = Bytes.new(pull)
          {% if properties.size > 0 %}
            case %key
            {% for name, value in properties %}
              when {{value[:key]}}.to_slice
                on_key_presence(:{{name.stringify}})
                %found{name} = true
                %var{name} =
                  {% if value[:nilable] || value[:has_default] %} pull.read_nil_or do {% end %}

                  {% if value[:converter] %}
                    {{value[:converter]}}.from_msgpack(pull)
                  {% else %}
                    ::Union({{value[:type]}}).new(pull)
                  {% end %}

                  {% if value[:nilable] || value[:has_default] %} end {% end %}
            {% end %}
            else
              on_unknown_msgpack_attribute(pull, %key)
            end
          {% else %}
            on_unknown_msgpack_attribute(pull, %key)
          {% end %}
        end

        {% for name, value in properties %}
          {% unless value[:nilable] || value[:has_default] %}
            if %var{name}.nil? && !%found{name} && !::Union({{value[:type]}}).nilable?
              raise ::MessagePack::TypeCastError.new("Missing msgpack attribute: {{value[:key].id}}", token.byte_number)
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
        {% end %}
      {% end %}
      after_initialize
    end

    macro use_msgpack_discriminator(field, mapping)
      {% unless mapping.is_a?(HashLiteral) || mapping.is_a?(NamedTupleLiteral) %}
        {% mapping.raise "mapping argument must be a HashLiteral or a NamedTupleLiteral, not #{mapping.class_name.id}" %}
      {% end %}

      def self.new(pull : ::MessagePack::Unpacker)
        node = pull.read_node
        pull2 = MessagePack::NodeUnpacker.new(node)
        discriminator_value = nil
        pull2.consume_table do |key|
          if key == {{field.id.stringify}}
            case token = pull2.read_token
            when MessagePack::Token::IntT, MessagePack::Token::StringT, MessagePack::Token::BoolT
              discriminator_value = token.value
              break
            else
              # nothing more to do
              raise ::MessagePack::TypeCastError.new("Msgpack discriminator field '{{field.id}}' has an invalid value type of #{MessagePack::Token.to_s(token)}", token.byte_number)
            end
          else
            pull2.skip_value
          end
        end

        unless discriminator_value
          raise ::MessagePack::UnpackError.new("Missing Msgpack discriminator field '{{field.id}}'", 0)
        end

        case discriminator_value
        {% for key, value in mapping %}
          {% if mapping.is_a?(NamedTupleLiteral) %}
            when {{key.id.stringify}}
          {% else %}
            {% if key.is_a?(StringLiteral) %}
              when {{key}}
            {% elsif key.is_a?(NumberLiteral) || key.is_a?(BoolLiteral) %}
              when {{key.id}}
            {% elsif key.is_a?(Path) %}
              when {{key.resolve}}
            {% else %}
              {% key.raise "mapping keys must be one of StringLiteral, NumberLiteral, BoolLiteral, or Path, not #{key.class_name.id}" %}
            {% end %}
          {% end %}
          {{value.id}}.new(__pull_for_msgpack_serializable: MessagePack::NodeUnpacker.new(node))
        {% end %}
        else
          raise ::MessagePack::UnpackError.new("Unknown '{{field.id}}' discriminator value: #{discriminator_value.inspect}", 0)
        end
      end
    end

    protected def after_initialize
    end

    protected def on_unknown_msgpack_attribute(pull, key : Bytes)
      pull.skip_value
    end

    protected def additional_write_fields_count
      0
    end

    protected def on_to_msgpack(packer : ::MessagePack::Packer)
    end

    protected def on_key_presence(key)
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
        raise ::MessagePack::TypeCastError.new("Unknown msgpack attribute: #{String.new(key)}")
      end
    end

    module Unmapped
      @[MessagePack::Field(ignore: true)]
      property msgpack_unmapped = Hash(String, ::MessagePack::Type).new

      protected def on_unknown_msgpack_attribute(pull, key)
        msgpack_unmapped[String.new(key)] = pull.read
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

    module Presence
      @[MessagePack::Field(ignore: true)]
      property _msgpack_keys_presence = Set(Symbol).new

      protected def on_key_presence(key)
        _msgpack_keys_presence << key
      end

      def key_present?(key)
        _msgpack_keys_presence.includes?(key)
      end
    end
  end
end
