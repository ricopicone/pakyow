# frozen_string_literal: true

require "cgi"
require "forwardable"

require "oga"

require "pakyow/support/inflector"
require "pakyow/support/silenceable"

require "string_doc/objects/mutable"
require "string_doc/objects/immutable"

# String-based XML document optimized for fast manipulation and rendering.
#
# In Pakyow, we rarely care about every node in a document. Instead, only significant nodes and
# immediate children are available for manipulation. StringDoc provides "just enough" for our
# purposes. A StringDoc is represented as a multi- dimensional array of strings, making
# rendering essentially a +flatten.join+.
#
# Because less work is performed during render, StringDoc is consistently faster than rendering
# a document using Nokigiri or Oga. One obvious tradeoff is that parsing is much slower (we use
# Oga to parse the XML, then convert it into a StringDoc). This is an acceptable tradeoff
# because we only pay the parsing cost once (when the Pakyow application boots).
#
# All that to say, StringDoc is a tool that is very specialized to Pakyow's use-case. Use it
# only when a longer parse time is acceptable and you only care about a handful of identifiable
# nodes in a document.
#
class StringDoc
  require "string_doc/attributes"
  require "string_doc/node"

  class << self
    # Creates an empty doc.
    #
    def empty(type)
      allocate.tap do |doc|
        type_class = StringDoc::Objects.const_get(Pakyow::Support.inflector.classify(type))
        doc.instance_variable_set(:@object, type_class.new([]))
        doc.instance_variable_set(:@type_class, type_class)
        doc.instance_variable_set(:@type, type)
        doc.instance_variable_set(:@collapsed, nil)
      end
    end

    # Registers a significant node with a name and an object to handle parsing.
    #
    def significant(name, object)
      significant_types[name] = object
    end

    # Yields nodes from an oga document, breadth-first.
    #
    def breadth_first(doc)
      queue = [doc]

      until queue.empty?
        element = queue.shift

        if element == doc
          queue.concat(element.children.to_a); next
        end

        yield element
      end
    end

    # Returns attributes for an oga element.
    #
    def attributes(element)
      if element.is_a?(Oga::XML::Element)
        element.attributes
      else
        []
      end
    end

    # Builds a string-based representation of attributes for an oga element.
    #
    def attributes_string(element)
      attributes(element).each_with_object(String.new) do |attribute, string|
        string << " #{attribute.name}=\"#{attribute.value}\""
      end
    end

    # Determines the significance of +element+.
    #
    def find_significance(element)
      significant_types.each_with_object([]) do |(key, object), significance|
        if object.significant?(element)
          significance << key
        end
      end
    end

    # Returns true if the given Oga element contains a child node that is significant.
    #
    def contains_significant_child?(element)
      element.children.each do |child|
        return true if find_significance(child).any?
        return true if contains_significant_child?(child)
      end

      false
    end

    # @api private
    def significant_types
      @significant_types ||= {}
    end
  end

  include Pakyow::Support::Silenceable

  # @api private
  attr_reader :collapsed, :object, :type

  extend Forwardable
  def_delegators :@object, :nodes

  # Creates a +StringDoc+ from an html string.
  #
  def initialize(html, type: :mutable)
    @type, @collapsed = type, nil
    @type_class = StringDoc::Objects.const_get(Pakyow::Support.inflector.classify(type))
    @object = @type_class.new(parse(Oga.parse_html(html)))
  end

  # def copy(nodes: @nodes, collapsed: @collapsed)
  #   self.class.allocate.tap do |copy|
  #     copy.instance_variable_set(:@nodes, nodes)
  #     copy.instance_variable_set(:@collapsed, collapsed)
  #   end
  # end

  # @api private
  def initialize_copy(_)
    super

    @object = from_nodes(nodes.map(&:dup))
  end

  include Enumerable

  def each(&block)
    return enum_for(:each) unless block_given?

    nodes.each do |node|
      yield node

      if node.children.is_a?(StringDoc)
        node.children.each(&block)
      else
        yield node.children
      end
    end
  end

  # Yields each node matching the significant type.
  #
  def each_significant_node(type)
    return enum_for(:each_significant_node, type) unless block_given?

    each do |node|
      yield node if node.is_a?(Node) && node.significant?(type)
    end
  end

  # Yields each node matching the significant type, without descending into nodes that are of that type.
  #
  def each_significant_node_without_descending(type, &block)
    return enum_for(:each_significant_node_without_descending, type) unless block_given?

    nodes.each do |node|
      if node.is_a?(Node)
        if node.significant?(type)
          yield node
        elsif node.children.is_a?(self.class)
          node.children.each_significant_node_without_descending(type, &block)
        end
      end
    end
  end

  # Yields each node matching the significant type and name.
  #
  # @see find_significant_nodes
  #
  def each_significant_node_with_name(type, name)
    return enum_for(:each_significant_node_with_name, type, name) unless block_given?

    each_significant_node(type) do |node|
      yield node if node.label(type) == name
    end
  end

  # Yields each node matching the significant type and name, without descending into nodes that are of that type.
  #
  # @see find_significant_nodes
  #
  def each_significant_node_with_name_without_descending(type, name)
    return enum_for(:each_significant_node_with_name_without_descending, type, name) unless block_given?

    each_significant_node_without_descending(type) do |node|
      yield node if node.label(type) == name
    end
  end

  # Returns the first node matching the significant type.
  #
  def find_first_significant_node(type)
    find { |node|
      node.significant?(type)
    }
  end

  # Returns the first node matching the significant type, without descending into nodes that are of that type.
  #
  def find_first_significant_node_without_descending(type)
    each_significant_node_without_descending(type) do |node|
      return node if node.significant?(type)
    end

    nil
  end

  # Returns nodes matching the significant type.
  #
  def find_significant_nodes(type)
    [].tap do |nodes|
      each_significant_node(type) do |node|
        nodes << node
      end
    end
  end

  # Returns nodes matching the significant type, without descending into nodes that are of that type.
  #
  def find_significant_nodes_without_descending(type)
    [].tap do |nodes|
      each_significant_node_without_descending(type) do |node|
        nodes << node
      end
    end
  end

  # Returns nodes matching the significant type and name.
  #
  # @see find_significant_nodes
  #
  def find_significant_nodes_with_name(type, name)
    [].tap do |nodes|
      each_significant_node_with_name(type, name) do |node|
        nodes << node
      end
    end
  end

  # Returns nodes matching the significant type and name, without descending into nodes that are of that type.
  #
  # @see find_significant_nodes
  #
  def find_significant_nodes_with_name_without_descending(type, name)
    [].tap do |nodes|
      each_significant_node_with_name_without_descending(type, name) do |node|
        nodes << node
      end
    end
  end

  # Converts the document to an xml string.
  #
  def to_xml
    render
  end
  alias to_html to_xml
  alias to_s to_xml

  def ==(other)
    other.is_a?(self.class) && @object.nodes == other.object.nodes
  end

  def collapse(*significance)
    if significance?(*significance)
      nodes.each do |node|
        node.children.collapse(*significance)
      end
    else
      @collapsed = to_xml
      @object = self.class.empty(@type)
    end
  end

  def significance?(*significance)
    nodes.any? { |node|
      node.significance?(*significance) || node.children.significance?(*significance)
    }
  end

  def remove_empty_nodes
    nodes.each do |node|
      node.children.remove_empty_nodes
    end

    unless empty?
      nodes.delete_if(&:empty?)
    end
  end

  def empty?
    nodes.empty?
  end

  def render(doc = self, string = String.new)
    if doc.collapsed && doc.empty?
      string << doc.collapsed
    else
      doc.nodes.each do |node|
        if node.is_a?(Node)
          string << node.tag_open_start

          node.attributes.each_string do |attribute_string|
            string << attribute_string
          end

          string << node.tag_open_end

          case node.children
          when StringDoc
            render(node.children, string)
          else
            string << node.children
          end

          string << node.tag_close
        else
          string << node.to_s
        end
      end

      string
    end
  end

  %i(clear remove replace append prepend insert_after insert_before remove_node replace_node).each do |action|
    class_eval <<~CODE, __FILE__, __LINE__ + 1
      def #{action}(*args)
        tap do
          @object.#{action}(*args)
        end
      end
    CODE
  end

  private

  # Parses an Oga document into an array of node objects.
  #
  def parse(doc)
    nodes = []

    unless doc.is_a?(Oga::XML::Element) || !doc.respond_to?(:doctype) || doc.doctype.nil?
      nodes << Node.new("<!DOCTYPE html>", type: @type)
    end

    self.class.breadth_first(doc) do |element|
      significance = self.class.find_significance(element)

      unless significance.any? || self.class.contains_significant_child?(element)
        # Nothing inside of the node is significant, so collapse it to a single node.
        nodes << Node.new(element.to_xml, type: @type); next
      end

      node = if significance.any?
        build_significant_node(element, significance)
      elsif element.is_a?(Oga::XML::Text) || element.is_a?(Oga::XML::Comment)
        Node.new(element.to_xml, type: @type)
      else
        Node.new("<#{element.name}#{self.class.attributes_string(element)}", type: @type)
      end

      if element.is_a?(Oga::XML::Element)
        node.close(element.name, from_nodes(parse(element)))
      end

      nodes << node
    end

    nodes
  end

  # Attributes that should be prefixed with +data-+
  #
  DATA_ATTRS = %i(ui config binding endpoint endpoint-action version).freeze

  # Attributes that will be turned into +StringDoc+ labels
  #
  LABEL_ATTRS = %i(ui config mode version include exclude endpoint endpoint-action prototype binding).freeze

  LABEL_MAPPING = {
    ui: :component
  }

  # Attributes that should be deleted from the view
  #
  DELETED_ATTRS = %i(include exclude prototype).freeze

  ATTR_MAPPING = {
    binding: :b,
    endpoint: :e,
    "endpoint-action": :"e-a",
    version: :v
  }

  def attributes_hash(element)
    self.class.attributes(element).each_with_object({}) { |attribute, elements|
      elements[attribute.name.to_sym] = CGI.escape_html(attribute.value.to_s)
    }
  end

  def labels_hash(element)
    self.class.attributes(element).dup.each_with_object({}) { |attribute, labels|
      attribute_name = attribute.name.to_sym

      if LABEL_ATTRS.include?(attribute_name)
        labels[LABEL_MAPPING.fetch(attribute_name, attribute_name)] = attribute.value.to_s.to_sym
      end
    }
  end

  def build_significant_node(element, significance)
    if element.is_a?(Oga::XML::Element)
      attributes = attributes_hash(element).each_with_object({}) { |(key, value), remapped_attributes|
        unless DELETED_ATTRS.include?(key)
          remapped_key = ATTR_MAPPING.fetch(key, key)

          if DATA_ATTRS.include?(key)
            remapped_key = :"data-#{remapped_key}"
          end

          remapped_attributes[remapped_key] = value || ""
        end
      }

      labels = labels_hash(element)

      if labels.include?(:binding)
        find_channel_for_binding!(element, attributes, labels)
      end

      Node.new("<#{element.name}", Attributes.new(attributes, @type), type: @type, significance: significance, labels: labels, parent: self)
    else
      name = element.text.strip.match(/@[^\s]*\s*([a-zA-Z0-9\-_]*)/)[1]
      labels = significance.each_with_object({}) { |significant_type, labels_hash|
        # FIXME: remove this special case logic
        labels_hash[significant_type] = if name.empty? && significant_type == :container
          Pakyow::Presenter::Page::DEFAULT_CONTAINER
        else
          name.to_sym
        end
      }

      Node.new(element.to_xml, type: @type, significance: significance, parent: self, labels: labels)
    end
  end

  def find_channel_for_binding!(element, attributes, labels)
    channel = semantic_channel_for_element(element)

    binding_parts = labels[:binding].to_s.split(":").map(&:to_sym)
    binding_name_parts = binding_parts[0].to_s.split(".", 2)
    labels[:binding] = binding_name_parts[0].to_sym
    labels[:binding_prop] = binding_name_parts[1].to_sym if binding_name_parts.length > 1
    attributes[:"data-b"] = binding_parts[0]

    channel.concat(binding_parts[1..-1])
    labels[:channel] = channel

    combined_channel = channel.join(":")
    labels[:combined_channel] = combined_channel

    unless channel.empty?
      attributes[:"data-c"] = combined_channel
    end
  end

  SEMANTIC_TAGS = %w(
    article
    aside
    details
    footer
    form
    header
    main
    nav
    section
    summary
  ).freeze

  def semantic_channel_for_element(element, channel = [])
    if element.parent.is_a?(Oga::XML::Element)
      semantic_channel_for_element(element.parent, channel)
    end

    if SEMANTIC_TAGS.include?(element.name)
      channel << element.name.to_sym
    end

    channel
  end

  def from_nodes(nodes)
    self.class.allocate.tap do |instance|
      instance.instance_variable_set(:@object, @type_class.new(nodes))
      instance.instance_variable_set(:@type_class, @type_class)
      instance.instance_variable_set(:@type, @type)
      instance.instance_variable_set(:@collapsed, nil)

      nodes.each do |node|
        node.parent = instance#.object
      end
    end
  end
end
