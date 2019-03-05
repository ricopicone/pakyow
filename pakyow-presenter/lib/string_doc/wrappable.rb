# frozen_string_literal: true

require "pakyow/support/extension"

class StringDoc
  module Wrappable
    extend Pakyow::Support::Extension

    class_methods do
      def wrap(class_to_wrap, wrapping_class)
        wrapping_class.const_get(:ACTIONS).each do |method_to_delegate|
          if method_to_delegate.to_s == "[]="
            wrapping_class.class_eval <<~CODE, __FILE__, __LINE__ + 1
              def #{method_to_delegate}(key, value)
                @delegate.transform(@object) do |node|
                  #{self}.set(node, key, value)
                end
              end
            CODE
          elsif method_to_delegate.to_s.end_with?("=")
            wrapping_class.class_eval <<~CODE, __FILE__, __LINE__ + 1
              def #{method_to_delegate}(value)
                @delegate.transform(@object) do |node|
                  #{self}.set_#{method_to_delegate[0..-2]}(node, value)
                end
              end
            CODE
          else
            wrapping_class.class_eval <<~CODE, __FILE__, __LINE__ + 1
              def #{method_to_delegate}(*args, &block)
                @delegate.transform(@object) do |node|
                  #{self}.#{method_to_delegate}(node, *args, &block)
                end
              end
            CODE
          end
        end

        (class_to_wrap.public_instance_methods - Object.public_instance_methods - wrapping_class.public_instance_methods).each do |method_to_delegate|
          if method_to_delegate.to_s.start_with?("each")
            wrapping_class.class_eval <<~CODE, __FILE__, __LINE__ + 1
              def #{method_to_delegate}(*args, &block)
                object = if block_given?
                  @object.#{method_to_delegate}(*args) do |yielded_object|
                    wrap(yielded_object).tap do |transformable|
                      yield transformable if block_given?
                    end
                  end
                else
                  to_enum(:#{method_to_delegate}, *args)
                end

                wrap(object)
              end
            CODE
          else
            wrapping_class.class_eval <<~CODE, __FILE__, __LINE__ + 1
              def #{method_to_delegate}(*args, &block)
                wrap(@object.#{method_to_delegate}(*args, &block))
              end
            CODE
          end
        end
      end
    end

    private

    require "string_doc/immutable"
    require "string_doc/node/immutable"
    require "string_doc/attributes/immutable"

    WRAPPABLE = {
      StringDoc => StringDoc::Immutable,
      Node => Node::Immutable,
      Attributes => Attributes::Immutable
    }.freeze

    def wrap(object)
      if wrapped = WRAPPABLE[object.class]
        wrapped.new(object, @delegate)
      elsif object.is_a?(Array)
        object.map { |value|
          wrap(value)
        }
      else
        object
      end
    end

    def unwrap(object)
      while object.respond_to?(:object)
        object = object.object
      end

      object
    end
  end
end
