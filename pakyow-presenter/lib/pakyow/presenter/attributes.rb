# frozen_string_literal: true

require "forwardable"

require "pakyow/support/safe_string"

require "pakyow/presenter/attributes/boolean"
require "pakyow/presenter/attributes/hash"
require "pakyow/presenter/attributes/set"
require "pakyow/presenter/attributes/string"

module Pakyow
  module Presenter
    class Attributes
      class << self
        def typed_value_for_attribute_with_name(value, name)
          type = type_of_attribute(name.to_sym)

          if value.is_a?(type)
            value
          else
            type.parse(value)
          end
        end

        def type_of_attribute(attribute)
          ATTRIBUTE_TYPES[attribute.to_sym] || ATTRIBUTE_TYPE_DEFAULT
        end

        def default_value_for_attribute(attribute)
          type = type_of_attribute(attribute.to_sym)
          if type == ATTRIBUTE_TYPE_SET
            ::Set.new
          elsif type == ATTRIBUTE_TYPE_HASH
            ::Hash.new
          elsif type == ATTRIBUTE_TYPE_BOOLEAN
            false
          else
            ::String.new
          end
        end
      end

      # Object for hash attributes
      ATTRIBUTE_TYPE_HASH = Attributes::Hash
      # Object for set attributes
      ATTRIBUTE_TYPE_SET = Attributes::Set
      # Object for boolean attributes
      ATTRIBUTE_TYPE_BOOLEAN = Attributes::Boolean
      # Default attribute object
      ATTRIBUTE_TYPE_DEFAULT = Attributes::String

      # Maps non-default attributes to their type
      ATTRIBUTE_TYPES = {
        class: ATTRIBUTE_TYPE_SET,
        style: ATTRIBUTE_TYPE_HASH,
        selected: ATTRIBUTE_TYPE_BOOLEAN,
        checked: ATTRIBUTE_TYPE_BOOLEAN,
        disabled: ATTRIBUTE_TYPE_BOOLEAN,
        readonly: ATTRIBUTE_TYPE_BOOLEAN,
        multiple: ATTRIBUTE_TYPE_BOOLEAN,
      }.freeze

      include Support::SafeStringHelpers

      extend Forwardable
      def_delegators :@view, :object
      def_delegators :object, :attributes
      def_delegators :attributes, :keys, :each

      # Wraps a hash of view attributes
      #
      # @param attributes [Hash]
      #
      def initialize(view, attributes)
        view.object = view.delegate.replace_node_attributes(
          view.object,
          ::Hash[attributes.hash.map { |name, value|
            [name, Attributes.typed_value_for_attribute_with_name(value, name)]
          }]
        )

        @view = view
      end

      def [](attribute)
        attribute = normalize_attribute_name(attribute)
        attribute_type = self.class.type_of_attribute(attribute)

        if attribute_type == ATTRIBUTE_TYPE_BOOLEAN
          attributes.key?(attribute)
        else
          unless attributes[attribute]
            self[attribute] = attribute_type.new(self.class.default_value_for_attribute(attribute))
          end

          attributes[attribute]
        end
      end

      def []=(attribute, value)
        attribute = ensure_html_safety(normalize_attribute_name(attribute)).to_s

        if value.nil?
          @view.object = @view.delegate.delete_node_attribute(@view.object, attribute)
        elsif self.class.type_of_attribute(attribute) == ATTRIBUTE_TYPE_BOOLEAN
          if value
            @view.object = @view.delegate.set_node_attribute(
              @view.object, attribute, self.class.typed_value_for_attribute_with_name(attribute, attribute)
            )
          else
            @view.object = @view.delegate.delete_node_attribute(@view.object, attribute)
          end
        else
          @view.object = @view.delegate.set_node_attribute(
            @view.object, attribute, self.class.typed_value_for_attribute_with_name(value, attribute)
          )
        end
      end

      def has?(attribute)
        attributes.key?(normalize_attribute_name(attribute))
      end

      def delete(attribute)
        @view.object = @view.delegate.delete_node_attribute(
          @view.object, normalize_attribute_name(attribute)
        )
      end

      private

      def normalize_attribute_name(name)
        name.to_s
      end
    end
  end
end
