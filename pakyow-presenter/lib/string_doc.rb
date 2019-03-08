# frozen_string_literal: true

require "cgi"

require "oga"

require "pakyow/support/silenceable"

class StringDoc
  require "string_doc/node"
  require "string_doc/attributes"

  class << self
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

    # @api private
    def nodes_from_doc_or_string(doc_node_or_string)
      case doc_node_or_string
      when StringDoc
        doc_node_or_string.nodes
      when Node
        [doc_node_or_string]
      else
        StringDoc.new(doc_node_or_string.to_s).nodes
      end
    end
  end

  module Traversal
    def each(nodes = @nodes, &block)
      return enum_for(:each) unless block_given?

      nodes.each do |node|
        yield node

        if children = @node_children[node]
          each(children, &block)
        end
      end
    end

    # Yields each node matching the significant type.
    #
    def each_significant_node(type)
      return enum_for(:each_significant_node, type) unless block_given?

      each do |node|
        yield node if node.significant?(type)
      end
    end

    # Yields each node matching the significant type, without descending into nodes that are of that type.
    #
    def each_significant_node_without_descending(type, nodes = @nodes, &block)
      return enum_for(:each_significant_node_without_descending, type) unless block_given?

      nodes.each do |node|
        if node.significant?(type)
          yield node
        elsif children = @node_children[node]
          each_significant_node_without_descending(type, children, &block)
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
  end

  module Mutation
    def replace_node(node_to_replace, replacement, children = [], transformations = {})
      tap do
        nodes = self.class.nodes_from_doc_or_string(replacement)

        # Replace current node at the top level.
        #
        if index = @nodes.index(node_to_replace)
          @nodes.insert(index + 1, *nodes)
          @nodes.delete_at(index)
        end

        # Replace current node if it is a child of another node.
        #
        @node_children.each_value do |node_children|
          if index = node_children.index(node_to_replace)
            node_children.insert(index + 1, *nodes)
            node_children.delete_at(index)
          end
        end

        # Remove children for the current node.
        #
        remove_node_children(node_to_replace)

        # Remove transformations from the current node.
        #
        current_transformations = @node_transformations.delete(node_to_replace)

        nodes.each do |each_node|
          # Set node children.
          #
          set_node_children(each_node, children)

          # Reassign transformations for the node.
          #
          if current_transformations
            @node_transformations[each_node] = current_transformations
          end

          # Insert transformations for the replacement node.
          #
          set_node_transformations(each_node, transformations)
        end
      end
    end

    def replace_node_children(node, replacement, children = [], transformations = {})
      tap do
        remove_node_children(node)
        replacement_nodes = self.class.nodes_from_doc_or_string(replacement)
        @node_children[node] = replacement_nodes
        replacement_nodes.each do |replacement_node|
          set_node_children(replacement_node, children)
          set_node_transformations(replacement_node, transformations)
        end
      end
    end

    def set_node_html(node, html)
      replace_node_children(node, Node.new(html.to_s))
    end

    def remove_node(node_to_remove)
      tap do
        # Remove node at the top level.
        #
        if index = @nodes.index(node_to_remove)
          @nodes.delete_at(index)
        end

        # Remove node if it is a child of another node.
        #
        @node_children.each_value do |node_children|
          if index = node_children.index(node_to_remove)
            node_children.delete_at(index)
          end
        end

        # Remove children for the node.
        #
        if children = @node_children.delete(node_to_remove)
          children.each do |child|
            remove_node(child)
          end
        end

        # Remove transformations for the node.
        #
        @node_transformations.delete(node_to_remove)
      end
    end

    def remove_node_children(node)
      tap do
        if children = @node_children.delete(node)
          children.each do |child|
            remove_node(child)
          end
        end
      end
    end

    def insert_after_node(node, insertable, children = [], transformations = {})
      tap do
        insertable_nodes = self.class.nodes_from_doc_or_string(insertable)

        if index = @nodes.index(node)
          @nodes.insert(index + 1, *insertable_nodes)
        else
          @node_children.values.each do |children_for_node|
            if index = children_for_node.index(node)
              children_for_node.insert(index + 1, *insertable_nodes)
            end
          end
        end

        insertable_nodes.each do |insertable_node|
          set_node_children(insertable_node, children)
          set_node_transformations(insertable_node, transformations)
        end
      end
    end

    def append_to_node(node, appendable, children = [], transformations = {})
      tap do
        appendable_nodes = self.class.nodes_from_doc_or_string(appendable)
        (@node_children[node] ||= []).concat(appendable_nodes)
        appendable_nodes.each do |appendable_node|
          set_node_children(appendable_node, children)
          set_node_transformations(appendable_node, transformations)
        end
      end
    end

    def prepend_to_node(node, prependable, children = [], transformations = {})
      tap do
        prependable_nodes = self.class.nodes_from_doc_or_string(prependable)
        (@node_children[node] ||= []).unshift(*prependable_nodes)
        prependable_nodes.each do |prependable_node|
          set_node_children(prependable_node, children)
          set_node_transformations(prependable_node, transformations)
        end
      end
    end

    def set_node_label(node, key, value)
      tap do
        labels = node.labels.dup
        labels[key.to_sym] = value
        node_did_mutate(node, node.copy(labels: labels))
      end
    end

    def delete_node_label(node, key)
      tap do
        labels = node.labels.dup
        labels.delete(key.to_sym)
        node_did_mutate(node, node.copy(labels: labels))
      end
    end

    def set_node_attribute(node, key, value)
      tap do
        attributes = node.attributes.hash.dup
        attributes[key.to_s] = value
        node_did_mutate(node, node.copy(attributes: Attributes.new(attributes)))
      end
    end

    def delete_node_attribute(node, key)
      tap do
        attributes = node.attributes.hash.dup
        attributes.delete(key.to_s)
        node_did_mutate(node, node.copy(attributes: Attributes.new(attributes)))
      end
    end

    def replace_node_attributes(node, hash)
      tap do
        node_did_mutate(node, node.copy(attributes: Attributes.new(hash)))
      end
    end

    private

    def node_did_mutate(node, mutated_node)
      # Replace the current node with the mutated node.
      #
      if index = @nodes.index(node)
        @nodes.insert(index + 1, mutated_node)
        @nodes.delete_at(index)
      end

      # Replace current node if it is a child of another node.
      #
      @node_children.each_value do |node_children|
        if index = node_children.index(node)
          node_children.insert(index + 1, mutated_node)
          node_children.delete_at(index)
        end
      end

      # Reassign the current node's children.
      #
      @node_children[mutated_node] = @node_children.delete(node)

      # Reassign the current node's transformations.
      #
      @node_transformations[mutated_node] = @node_transformations.delete(node)
    end

    def set_node_children(node, children)
      @node_children[node] = []
      children.each do |child, nested_children|
        @node_children[node] << child
        set_node_children(child, nested_children)
      end
    end

    def set_node_transformations(node, tuple)
      @node_transformations[node] = tuple[0]

      if nested = tuple[1]
        nested.each do |nested_node, nested_transformations|
          set_node_transformations(nested_node, nested_transformations)
        end
      end
    end
  end

  module Rendering
    def transform(node, priority: :default, &block)
      (@node_transformations[node] ||= { high: [], default: [], low: [] })[priority] << block
    end

    def render(output = String.new, nodes: @nodes, context: self, on_error: nil)
      nodes.each do |node|
        catch :rendered_node do
          if prioritized_transformations = @node_transformations.delete(node)
            prioritized_transformations.each_value do |transformations|
              transformations.each do |transformation|
                node = context.instance_exec(node, &transformation)
              rescue => error
                node = if on_error
                  on_error.call(error, node)
                else
                  nil
                end
              ensure
                if node.nil?
                  throw :rendered_node
                elsif node.is_a?(String)
                  output << node
                  throw :rendered_node
                end
              end
            end
          end

          output << node.tag_open_start

          node.attributes.each_string do |attribute_string|
            output << attribute_string
          end

          output << node.tag_open_end

          if children = @node_children[node]
            render(output, nodes: children, context: context, on_error: on_error)
          end

          output << node.tag_close
        end
      end

      output
    end
    alias to_s render
    alias to_xml render
    alias to_html render
  end

  include Enumerable

  include Mutation
  include Traversal
  include Rendering

  # @api private
  attr_reader :nodes, :node_children, :node_transformations

  def initialize(html)
    @nodes, @node_children, @node_transformations = [], {}, {}
    build(Oga.parse_html(html), true)
  end

  def initialize_copy(_)
    super

    @nodes = @nodes.dup
    @node_children = Hash[@node_children.map { |key, value| [key, value.dup] }]
    @node_transformations = @node_transformations.dup
  end

  def ==(other)
    other.is_a?(StringDoc) && @nodes == other.nodes && @node_children == other.node_children
  end

  # Returns an array of tuples representing child nodes and their children:
  #
  #   [[child, ...], ...]
  #
  def children_for_node(node)
    (@node_children[node] || []).map { |child|
      [child, children_for_node(child)]
    }
  end

  # Returns a tuple with transformations for the node and transformations for each child:
  #
  #   [transformations, [child, transformations, ...]]
  #
  def transformations_for_node(node)
    [@node_transformations[node] || {}, (@node_children[node] || []).map { |child| [child, transformations_for_node(child)] }]
  end

  private

  def build(oga, top_level = false)
    nodes = []

    unless oga.is_a?(Oga::XML::Element) || !oga.respond_to?(:doctype) || oga.doctype.nil?
      nodes << add_node(Node.new("<!DOCTYPE html>"), top_level)
    end

    self.class.breadth_first(oga) do |element|
      significance = self.class.find_significance(element)

      unless significance.any? || self.class.contains_significant_child?(element)
        element_xml = element.to_xml.strip

        unless element_xml.empty?
          # Nothing inside of the node is significant, so collapse it to a single node.
          nodes << add_node(Node.new(element_xml), top_level)
        end

        next
      end

      node = if significance.any?
        build_significant_node(element, significance)
      elsif element.is_a?(Oga::XML::Text) || element.is_a?(Oga::XML::Comment)
        element_xml = element.to_xml.strip
        if element_xml.empty?
          nil
        else
          Node.new(element_xml)
        end
      else
        Node.new("<#{element.name}#{self.class.attributes_string(element)}")
      end

      if node
        if element.is_a?(Oga::XML::Element)
          node.close(element.name)
          @node_children[node] = build(element)
        end

        nodes << add_node(node, top_level)
      end
    end

    nodes
  end

  def add_node(node, top_level = false)
    if top_level
      @nodes << node
    end

    node
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
    StringDoc.attributes(element).each_with_object({}) { |attribute, elements|
      elements[attribute.name.to_sym] = CGI.escape_html(attribute.value.to_s)
    }
  end

  def labels_hash(element)
    StringDoc.attributes(element).dup.each_with_object({}) { |attribute, labels|
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

      Node.new("<#{element.name}", Attributes.new(attributes), significance: significance, labels: labels)
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

      Node.new(element.to_xml, significance: significance, labels: labels)
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
end
