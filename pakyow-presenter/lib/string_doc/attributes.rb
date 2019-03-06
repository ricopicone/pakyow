# frozen_string_literal: true

require "forwardable"

require "string_doc/attributes/objects/mutable"
require "string_doc/attributes/objects/immutable"

class StringDoc
  # String-based XML attributes.
  #
  class Attributes
    OPENING = '="'
    CLOSING = '"'
    SPACING = " "

    include Pakyow::Support::SafeStringHelpers

    extend Forwardable
    def_delegators :@object, :attributes_hash
    def_delegators :attributes_hash, :keys, :each

    # @api private
    attr_reader :object

    def initialize(attributes_hash = {}, type = :mutable)
      @type, @type_class = type, StringDoc::Attributes::Objects.const_get(Pakyow::Support.inflector.classify(type))
      @object = @type_class.new(
        Hash[attributes_hash.map { |key, value|
          [key.to_s, value]
        }]
      )
    end

    def [](key)
      attributes_hash[key.to_s]
    end

    def key?(key)
      attributes_hash.key?(key.to_s)
    end

    def to_s
      string = attributes_hash.compact.map { |name, value|
        name + OPENING + value.to_s + CLOSING
      }.join(SPACING)

      if string.empty?
        string
      else
        SPACING + string
      end
    end

    def each_string
      if attributes_hash.empty?
        yield ""
      else
        attributes_hash.each do |name, value|
          yield SPACING
          yield name
          yield OPENING
          yield value.to_s
          yield CLOSING
        end
      end
    end

    def ==(other)
      other.is_a?(self.class) && attributes_hash == other.attributes_hash
    end

    %i([]= replace delete).each do |action|
      class_eval <<~CODE, __FILE__, __LINE__ + 1
        def #{action}(*args)
          tap do
            @object.#{action}(*args)
          end
        end
      CODE
    end

    # @api private
    def initialize_copy(_)
      super

      @object = @type_class.new(attributes_hash.each_with_object({}) { |(key, value), hash|
        hash[key] = value.dup
      })
    end

    # def copy(attributes_hash: @attributes_hash)
    #   self.class.allocate.tap do |copy|
    #     copy.instance_variable_set(:@attributes_hash, attributes_hash)
    #   end
    # end
  end
end
