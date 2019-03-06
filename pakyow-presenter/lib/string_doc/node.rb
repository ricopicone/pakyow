# frozen_string_literal: true

require "forwardable"

require "pakyow/support/deep_dup"
require "pakyow/support/inspectable"

require "string_doc/node/objects/mutable"
require "string_doc/node/objects/immutable"

class StringDoc
  # String-based XML node.
  #
  class Node
    class << self
      SELF_CLOSING = %w[area base basefont br hr input img link meta].freeze
      FORM_INPUTS  = %w[input select textarea button].freeze
      VALUELESS    = %w[select].freeze

      # Returns true if +tag+ is self-closing.
      #
      def self_closing?(tag)
        SELF_CLOSING.include?(tag)
      end

      # Returns true if +tag+ is a form input.
      #
      def form_input?(tag)
        FORM_INPUTS.include?(tag)
      end

      # Returns true if +tag+ does not contain a value.
      #
      def without_value?(tag)
        VALUELESS.include?(tag)
      end
    end

    attr_reader :object, :tag_open_start, :tag_open_end, :tag_close

    extend Forwardable
    def_delegators :@object, :attributes, :children, :labels, :parent, :parent=, :significance

    include Pakyow::Support::Inspectable
    inspectable :attributes, :children, :significance, :labels

    using Pakyow::Support::DeepDup

    def initialize(tag_open_start = "", attributes = Attributes.new, tag_open_end = "", children = nil, tag_close = "", type: :mutable, parent: nil, significance: [], labels: {})
      @type, @type_class = type, StringDoc::Node::Objects.const_get(Pakyow::Support.inflector.classify(type))
      @object = @type_class.new(self, parent: parent, attributes: attributes, children: children || StringDoc.empty(type), labels: labels, significance: significance)
      @tag_open_start, @tag_open_end, @tag_close = tag_open_start, tag_open_end, tag_close
    end

    # @api private
    def initialize_copy(_)
      super

      @object = @type_class.new(
        self,
        parent: parent,
        attributes: attributes.dup,
        children: children.dup,
        labels: labels.deep_dup,
        significance: significance.dup
      )
    end

    # def copy(children: @children, labels: @labels, attributes: @attributes)
    #   self.class.allocate.tap do |copy|
    #     copy.instance_variable_set(:@tag_open_start, @tag_open_start)
    #     copy.instance_variable_set(:@attributes, attributes)
    #     copy.instance_variable_set(:@tag_open_end, @tag_open_end)
    #     copy.instance_variable_set(:@children, children)
    #     copy.instance_variable_set(:@tag_close, @tag_close)
    #     copy.instance_variable_set(:@parent, @parent)
    #     copy.instance_variable_set(:@labels, labels)
    #     copy.instance_variable_set(:@significance, @significance)
    #   end
    # end

    def empty?
      to_s.strip.empty?
    end

    def significant?(type = nil)
      if type
        significance.include?(type.to_sym)
      else
        significance.any?
      end
    end

    def significance?(*types)
      (significance & types).any?
    end

    # Close self with +tag+ and children.
    #
    def close(tag, children)
      tap do
        @object.children = children
        @tag_open_end = tag ? ">" : ""
        @tag_close = (tag && !self.class.self_closing?(tag)) ? "</#{tag}>" : ""
      end
    end

    # Returns an array containing +self+ and any child nodes.
    #
    def with_children
      [self].tap do |self_with_children|
        if children
          self_with_children.concat(child_nodes)
        end
      end
    end

    REGEX_TAGS = /<[^>]*>/

    # Returns the text of this node and all children, joined together.
    #
    def text
      html.gsub(REGEX_TAGS, "")
    end

    # Returns the html contained within self.
    #
    def html
      children.to_s
    end

    # Returns the node's tagname.
    #
    def tagname
      @tag_open_start.gsub(/[^a-zA-Z]/, "")
    end

    # Returns the value for label with +name+.
    #
    def label(name)
      labels[name.to_sym]
    end

    # Returns true if label exists with +name+.
    #
    def labeled?(name)
      labels.key?(name.to_sym)
    end

    # Converts the node to an xml string.
    #
    def to_xml
      string_nodes.flatten.map(&:to_s).join
    end
    alias :to_html :to_xml
    alias :to_s :to_xml

    def ==(other)
      other.is_a?(Node) &&
        @tag_open_start == other.tag_open_start &&
        attributes == other.attributes &&
        @tag_open_end == other.tag_open_end &&
        children == other.children &&
        @tag_close == other.tag_close
    end

    def each
      return enum_for(:each) unless block_given?
      yield self
    end

    def each_significant_node(type, &block)
      return enum_for(:each_significant_node, type) unless block_given?

      if children.is_a?(StringDoc)
        children.each_significant_node(type, &block)
      end
    end

    def each_significant_node_without_descending(type, &block)
      return enum_for(:each_significant_node_without_descending, type) unless block_given?

      if children.is_a?(StringDoc)
        children.each_significant_node_without_descending(type, &block)
      end
    end

    def each_significant_node_with_name(type, name, &block)
      return enum_for(:each_significant_node_with_name, type, name) unless block_given?

      if children.is_a?(StringDoc)
        children.each_significant_node_with_name(type, name, &block)
      end
    end

    def each_significant_node_with_name_without_descending(type, name, &block)
      return enum_for(:each_significant_node_with_name_without_descending, type, name) unless block_given?

      if children.is_a?(StringDoc)
        children.each_significant_node_with_name_without_descending(type, name, &block)
      end
    end

    def find_first_significant_node(type)
      if children.is_a?(StringDoc)
        children.find_first_significant_node(type)
      else
        nil
      end
    end

    def find_first_significant_node_without_descending(type)
      if children.is_a?(StringDoc)
        children.find_first_significant_node_without_descending(type)
      else
        nil
      end
    end

    def find_significant_nodes(type)
      if children.is_a?(StringDoc)
        children.find_significant_nodes(type)
      else
        []
      end
    end

    def find_significant_nodes_without_descending(type)
      if children.is_a?(StringDoc)
        children.find_significant_nodes_without_descending(type)
      else
        []
      end
    end

    def find_significant_nodes_with_name(type, name)
      if children.is_a?(StringDoc)
        children.find_significant_nodes_with_name(type, name)
      else
        []
      end
    end

    def find_significant_nodes_with_name_without_descending(type, name)
      if children.is_a?(StringDoc)
        children.find_significant_nodes_with_name_without_descending(type, name)
      else
        []
      end
    end

    %i(replace remove html= replace_children clear after before append prepend set_label delete_label).each do |action|
      if action.to_s.end_with?("=")
        class_eval <<~CODE, __FILE__, __LINE__ + 1
          def #{action}(arg)
            tap do
              @object.#{action} arg
            end
          end
        CODE
      else
        class_eval <<~CODE, __FILE__, __LINE__ + 1
          def #{action}(*args)
            tap do
              @object.#{action}(*args)
            end
          end
        CODE
      end
    end

    private

    def string_nodes
      [@tag_open_start, attributes, @tag_open_end, children, @tag_close]
    end

    def child_nodes
      children.nodes.map(&:with_children).to_a.flatten
    end
  end
end
