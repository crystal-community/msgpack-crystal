require "./serializable"

module MessagePack
  module CompactSerializable
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
        {% options = @type.annotation(::MessagePack::CompactSerializable::Options) %}
        {% vars_count = (options && options[:variables]) %}

        {% properties = {} of Nil => Nil %}
        {% local_num = 0 %}
        {% max_id = 0 %}

        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(::MessagePack::Field) %}
          {% unless ann && ann[:ignore] %}
            {% num = ((ann && ann[:id]) || local_num) %}
            {% max_id = num if num > max_id %}
            {% raise "CompactSerializable(#{@type}): conflict @#{ivar} and @#{properties[num][:name]} both have number #{num}" if properties[num] %}
            {%
              properties[num] = {
                name:        ivar,
                type:        ivar.type,
                has_default: ivar.has_default_value?,
                default:     ivar.default_value,
                nilable:     ivar.type.nilable?,
                converter:   ann && ann[:converter],
              }
            %}
            {% local_num = local_num + 1 %}
          {% end %}
        {% end %}

        {% vars_count = max_id + 1 unless vars_count %}
        {% raise "CompactSerializable(#{@type}): number of properties(#{max_id + 1}) is more than allowed(#{vars_count})" if max_id >= vars_count %}

        token = pull.prefetch_token
        unless token.type == :ARRAY
          raise ::MessagePack::UnpackException.new("CompactSerializable(#{ {{@type.stringify}} }): unpacker expect Array type but got #{token.type}")
        end

        size = token.size

        unless size == {{max_id + 1}}
          if size < {{max_id + 1}}
            raise ::MessagePack::UnpackException.new("CompactSerializable(#{ {{@type.stringify}} }): expect array with #{{{max_id}} + 1} elements, but got #{size}")
          end

          if size > {{max_id + 1}}
            on_different_size({{max_id + 1}}, size)
          end
        end
        token.used = true

        {% for id, value in properties %}
          %found{id} = false
          %var{id} = nil
        {% end %}

        {% for id in 0...vars_count %}
          {% value = properties[id] %}
          {% unless value %}
            on_unknown_msgpack_attribute(pull, {{id}})
          {% else %}
            %found{id} = true
            %var{id} =
              {% if value[:nilable] || value[:has_default] %} pull.read_nil_or { {% end %}

              {% if value[:converter] %}
                {{value[:converter]}}.from_msgpack(pull)
              {% else %}
                ::Union({{value[:type]}}).new(pull)
              {% end %}

              {% if value[:nilable] || value[:has_default] %} } {% end %}
          {% end %}
        {% end %}

        (size - {{vars_count}}).times do |i|
          on_unknown_msgpack_attribute(pull, i.to_i32 + {{vars_count}})
        end

        {% for id, value in properties %}
          {% unless value[:nilable] || value[:has_default] %}
            if %var{id}.nil? && !::Union({{value[:type]}}).nilable?
              raise ::MessagePack::UnpackException.new("CompactSerializable(#{ {{@type.stringify}} }): unexpected nil for variable @#{ {{value[:name].stringify}} } at position #{ {{id}} }")
            end
          {% end %}

          {% if value[:nilable] %}
            {% if value[:has_default] != nil %}
              @{{value[:name]}} = %found{id} ? %var{id} : {{value[:default]}}
            {% else %}
              @{{value[:name]}} = %var{id}
            {% end %}
          {% elsif value[:has_default] %}
            @{{value[:name]}} = %var{id}.nil? ? {{value[:default]}} : %var{id}
          {% else %}
            @{{value[:name]}} = (%var{id}).as({{value[:type]}})
          {% end %}
        {% end %}
      {% end %}

      after_initialize
    end

    protected def after_initialize
    end

    protected def on_different_size(expect_size, got_size)
    end

    protected def on_unknown_msgpack_attribute(pull, id)
      pull.skip_value
    end

    protected def on_to_msgpack_unknown_field(packer, id)
      nil.to_msgpack(packer)
    end

    def to_msgpack(packer : ::MessagePack::Packer)
      {% begin %}
        {% options = @type.annotation(::MessagePack::CompactSerializable::Options) %}
        {% vars_count = (options && options[:variables]) %}

        {% properties = {} of Nil => Nil %}
        {% local_num = 0 %}
        {% max_id = 0 %}

        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(::MessagePack::Field) %}
          {% unless ann && ann[:ignore] %}
            {% num = ((ann && ann[:id]) || local_num) %}
            {% max_id = num if num > max_id %}
            {% raise "CompactSerializable(#{@type}): conflict @#{ivar} and @#{properties[num][:name]} both have number #{num}" if properties[num] %}
            {%
              properties[num] = {
                name:      ivar,
                type:      ivar.type,
                converter: ann && ann[:converter],
              }
            %}
            {% local_num = local_num + 1 %}
          {% end %}
        {% end %}

        {% vars_count = max_id + 1 unless vars_count %}
        {% raise "CompactSerializable(#{@type}): max id of property(#{max_id}) is more than allowed(#{vars_count - 1})" if max_id >= vars_count %}

        packer.write_array_start({{vars_count}})

        {% for id in 0...vars_count %}
          {% value = properties[id] %}
          {% unless value %}
            on_to_msgpack_unknown_field(packer, {{id}})
          {% else %}
            {% if value[:converter] %}
              {{ value[:converter] }}.to_msgpack(@{{value[:name]}}, packer)
            {% else %}
              @{{value[:name]}}.to_msgpack(packer)
            {% end %}
          {% end %}
        {% end %}
      {% end %}
    end

    module Strict
      protected def on_different_size(expect_size, got_size)
        raise ::MessagePack::UnpackException.new("CompactSerializable(#{{{@type.stringify}}}): got array(#{got_size}) bigger than expected(#{expect_size})")
      end
    end

    module Unmapped
      @[MessagePack::Field(ignore: true)]
      property msgpack_unmapped = Hash(Int32, ::MessagePack::Type).new

      protected def on_unknown_msgpack_attribute(pull, id)
        v = pull.read
        msgpack_unmapped[id] = v unless v.nil?
      end

      protected def on_to_msgpack_unknown_field(packer, id)
        msgpack_unmapped[id]?.to_msgpack(packer)
      end
    end
  end
end
