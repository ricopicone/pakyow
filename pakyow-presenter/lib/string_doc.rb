# frozen_string_literal: true

require "cgi"

require "oga"

require "pakyow/support/deep_dup"
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

    # @api private
    def ensure_string_doc_object(object)
      case object
      when StringDoc, Node
        object
      else
        StringDoc.new(object.to_s)
      end
    end
  end

  module Traversal
    def each(node = nil, nodes = @nodes, &block)
      return enum_for(:each, node) unless block_given?

      (node ? (@node_children[node] || []) : nodes).each do |each_node|
        yield each_node

        if children = @node_children[each_node]
          each(nil, children, &block)
        end
      end
    end

    # Yields each node matching the significant type.
    #
    def each_significant_node(type, node = nil)
      return enum_for(:each_significant_node, type, node) unless block_given?

      each(node) do |each_node|
        yield each_node if each_node.significant?(type)
      end
    end

    # Yields each node matching the significant type, without descending into nodes that are of that type.
    #
    def each_significant_node_without_descending(type, node = nil, nodes = @nodes, &block)
      return enum_for(:each_significant_node_without_descending, type, node) unless block_given?

      (node ? (@node_children[node] || []) : nodes).each do |each_node|
        if each_node.significant?(type)
          yield each_node
        elsif children = @node_children[each_node]
          each_significant_node_without_descending(type, nil, children, &block)
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
    def find_first_significant_node(type, node = nil)
      each(node).find { |found_node|
        found_node.significant?(type)
      }
    end

    # Returns the first node matching the significant type, without descending into nodes that are of that type.
    #
    def find_first_significant_node_without_descending(type, node = nil)
      each_significant_node_without_descending(type, node) do |each_node|
        return each_node if each_node.significant?(type)
      end

      nil
    end

    # Returns nodes matching the significant type.
    #
    def find_significant_nodes(type, node = nil)
      [].tap do |nodes|
        each_significant_node(type, node) do |each_node|
          nodes << each_node
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
        replacement = self.class.ensure_string_doc_object(replacement)
        replacement_nodes = self.class.nodes_from_doc_or_string(replacement)

        # Replace current node at the top level.
        #
        if index = @nodes.find_index { |n| n.object_id == node_to_replace.object_id }
          @nodes.insert(index + 1, *replacement_nodes)
          @nodes.delete_at(index)
        end

        # Replace current node if it is a child of another node.
        #
        @node_children.each_value do |node_children|
          if index = node_children.find_index { |n| n.object_id == node_to_replace.object_id }
            node_children.insert(index + 1, *replacement_nodes)
            node_children.delete_at(index)
          end
        end

        if replacement.is_a?(StringDoc)
          replacement_nodes.each do |each_node|
            # Set node children.
            #
            set_node_children(each_node, replacement.children_for_node(each_node))

            # Insert transformations for the replacement node.
            #
            set_node_transformations(each_node, replacement.transformations_for_node(each_node))
          end
        else
          replacement_nodes.each do |each_node|
            # Set node children.
            #
            set_node_children(each_node, children)

            # Insert transformations for the replacement node.
            #
            set_node_transformations(each_node, transformations)
          end
        end
      end
    end

    def replace_node_children(node, replacement, children = [], transformations = {})
      tap do
        remove_node_children(node)
        replacement = self.class.ensure_string_doc_object(replacement)
        replacement_nodes = self.class.nodes_from_doc_or_string(replacement)
        @node_children[node] = replacement_nodes

        if replacement.is_a?(StringDoc)
          replacement_nodes.each do |each_node|
            # Set node children.
            #
            set_node_children(each_node, replacement.children_for_node(each_node))

            # Insert transformations for the replacement node.
            #
            set_node_transformations(each_node, replacement.transformations_for_node(each_node))
          end
        else
          replacement_nodes.each do |replacement_node|
            set_node_children(replacement_node, children)
            set_node_transformations(replacement_node, transformations)
          end
        end
      end
    end

    def set_node_html(node, html)
      node_for_html = Node.new(html.to_s)
      replace_node_children(node, node_for_html)
      node_for_html
    end

    def remove_node(node_to_remove)
      tap do
        # Remove node at the top level.
        #
        if index = @nodes.find_index { |n| n.object_id == node_to_remove.object_id }
          @nodes.delete_at(index)
        end

        # Remove node if it is a child of another node.
        #
        @node_children.each_value do |node_children|
          if index = node_children.find_index { |n| n.object_id == node_to_remove.object_id }
            node_children.delete_at(index)
          end
        end
      end
    end

    def remove_node_children(node)
      tap do
        @node_children.delete(node)
      end
    end

    def insert_after_node(node, insertable, children = [], transformations = {})
      tap do
        insertable = self.class.ensure_string_doc_object(insertable)
        insertable_nodes = self.class.nodes_from_doc_or_string(insertable)

        if index = @nodes.find_index { |n| n.object_id == node.object_id }
          @nodes.insert(index + 1, *insertable_nodes)
        else
          @node_children.values.each do |children_for_node|
            if index = children_for_node.find_index { |n| n.object_id == node.object_id }
              children_for_node.insert(index + 1, *insertable_nodes)
            end
          end
        end

        if insertable.is_a?(StringDoc)
          insertable_nodes.each do |insertable_node|
            set_node_children(insertable_node, insertable.children_for_node(insertable_node))
            set_node_transformations(insertable_node, insertable.transformations_for_node(insertable_node))
          end
        else
          insertable_nodes.each do |insertable_node|
            set_node_children(insertable_node, children)
            set_node_transformations(insertable_node, transformations)
          end
        end
      end
    end

    def append_to_node(node, appendable, children = [], transformations = {})
      tap do
        appendable = self.class.ensure_string_doc_object(appendable)
        appendable_nodes = self.class.nodes_from_doc_or_string(appendable)
        (@node_children[node] ||= []).concat(appendable_nodes)

        if appendable.is_a?(StringDoc)
          appendable_nodes.each do |appendable_node|
            set_node_children(appendable_node, appendable.children_for_node(appendable_node))
            set_node_transformations(appendable_node, appendable.transformations_for_node(appendable_node))
          end
        else
          appendable_nodes.each do |appendable_node|
            set_node_children(appendable_node, children)
            set_node_transformations(appendable_node, transformations)
          end
        end
      end
    end

    def prepend_to_node(node, prependable, children = [], transformations = {})
      tap do
        prependable = self.class.ensure_string_doc_object(prependable)
        prependable_nodes = self.class.nodes_from_doc_or_string(prependable)
        (@node_children[node] ||= []).unshift(*prependable_nodes)

        if prependable.is_a?(StringDoc)
          prependable_nodes.each do |prependable_node|
            set_node_children(prependable_node, prependable.children_for_node(prependable_node))
            set_node_transformations(prependable_node, prependable.transformations_for_node(prependable_node))
          end
        else
          prependable_nodes.each do |prependable_node|
            set_node_children(prependable_node, children)
            set_node_transformations(prependable_node, transformations)
          end
        end
      end
    end

    def set_node_label(node, key, value)
      labels = node.labels.dup
      labels[key.to_sym] = value
      node_did_mutate(node, node.copy(labels: labels))
    end

    def delete_node_label(node, key)
      labels = node.labels.dup
      labels.delete(key.to_sym)
      node_did_mutate(node, node.copy(labels: labels))
    end

    def set_node_attribute(node, key, value)
      attributes = node.attributes.hash.dup
      attributes[key.to_s] = value
      node_did_mutate(node, node.copy(attributes: Attributes.new(attributes)))
    end

    def delete_node_attribute(node, key)
      attributes = node.attributes.hash.dup
      attributes.delete(key.to_s)
      node_did_mutate(node, node.copy(attributes: Attributes.new(attributes)))
    end

    def replace_node_attributes(node, hash)
      node_did_mutate(node, node.copy(attributes: Attributes.new(hash)))
    end

    def node_did_mutate(node, mutated_node)
      # Replace the current node with the mutated node.
      #
      if index = @nodes.find_index { |n| n.object_id == node.object_id }
        @nodes.insert(index + 1, mutated_node)
        @nodes.delete_at(index)
      end

      # Replace current node if it is a child of another node.
      #
      @node_children.each_value do |node_children|
        if index = node_children.find_index { |n| n.object_id == node.object_id }
          node_children.insert(index + 1, mutated_node)
          node_children.delete_at(index)
        end
      end

      # Reassign the current node's children.
      #
      if value = @node_children.delete(node)
        @node_children[mutated_node] = value
      end

      # Reassign the current node's transformations.
      #
      if value = @node_transformations.delete(node)
        @node_transformations[mutated_node] = value
      end

      mutated_node
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

    def render(output = String.new, node: nil, nodes: @nodes, context: self, on_error: nil)
      nodes = if node
        [node]
      else
        nodes
      end

      nodes.each do |each_node|
        catch :rendered_node do
          if prioritized_transformations = @node_transformations.delete(each_node)
            prioritized_transformations.each_value do |transformations|
              transformations.each do |transformation|
                each_node = context.instance_exec(each_node, &transformation)
              rescue => error
                each_node = if on_error
                  on_error.call(error, each_node)
                else
                  nil
                end
              ensure
                if each_node.nil?
                  throw :rendered_node
                elsif each_node.is_a?(String)
                  output << each_node
                  throw :rendered_node
                end
              end
            end
          end

          output << each_node.tag_open_start

          each_node.attributes.each_string do |attribute_string|
            output << attribute_string
          end

          output << each_node.tag_open_end

          if children = @node_children[each_node]
            render(output, nodes: children, context: context, on_error: on_error)
          end

          output << each_node.tag_close
        end
      end

      output
    end
    alias to_s render
    alias to_xml render
    alias to_html render
  end

  module Introspection
    def node_html(node)
      render(nodes: @node_children[node].to_a)
    end

    REGEX_TAGS = /<[^>]*>/

    def node_text(node)
      node_html(node).gsub(REGEX_TAGS, "")
    end
  end

  include Enumerable

  include Mutation
  include Traversal
  include Rendering
  include Introspection

  # @api private
  attr_reader :nodes, :node_children, :node_transformations

  def initialize(html)
    @nodes, @node_children, @node_transformations = [], {}, {}
    build(Oga.parse_html(html), true)
  end

  def self.empty
    allocate.tap do |instance|
      instance.instance_variable_set(:@nodes, [])
      instance.instance_variable_set(:@node_children, {})
      instance.instance_variable_set(:@node_transformations, {})
    end
  end

  def initialize_copy(_)
    super

    @nodes = @nodes.dup
    @node_children = Hash[@node_children.map { |key, value| [key, value.dup] }]
    @node_transformations = Hash[@node_transformations.map { | key, value| [key, value.dup] }]
  end

  def instance(node = nil)
    StringDoc.empty.tap do |instance|
      if node
        instance.nodes << deep_dup_node(node, instance)
      else
        @nodes.each do |each_node|
          instance.nodes << deep_dup_node(each_node, instance)
        end
      end
    end
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

  def ==(other)
    other.is_a?(StringDoc) && @nodes == other.nodes && @node_children == other.node_children
  end

  private

  using Pakyow::Support::DeepDup

  def deep_dup_node(node, target, source = self)
    node.dup.tap do |duped_node|
      if transformations = source.node_transformations[node]
        target.node_transformations[duped_node] = transformations.deep_dup
      end

      if children = source.node_children[node]
        target.node_children[duped_node] = children.map { |child_node|
          deep_dup_node(child_node, target, source)
        }
      end
    end
  end

  def build(oga, top_level = false)
    nodes = []

    unless oga.is_a?(Oga::XML::Element) || !oga.respond_to?(:doctype) || oga.doctype.nil?
      nodes << add_node(Node.new("<!DOCTYPE html>"), top_level)
    end

    self.class.breadth_first(oga) do |element|
      significance = self.class.find_significance(element)

      unless significance.any? || self.class.contains_significant_child?(element)
        element_xml = safe_strip(element.to_xml)

        unless element_xml.empty?
          # Nothing inside of the node is significant, so collapse it to a single node.
          nodes << add_node(Node.new(strip_whitespace_between_nodes(element_xml)), top_level)
        end

        next
      end

      node = if significance.any?
        build_significant_node(element, significance)
      elsif element.is_a?(Oga::XML::Text) || element.is_a?(Oga::XML::Comment)
        element_xml = safe_strip(element.to_xml)

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

  # Removes whitespace around tags and otherwise empty strings, but leaves spaces around text.
  #
  def safe_strip(xml)
    if (stripped = xml.strip).empty?
      xml = stripped
    else
      if xml[0] == "<"
        xml = xml.lstrip
      end

      if xml[-1] == ">"
        xml = xml.rstrip
      end

      xml = xml.gsub(/\n/, "")
    end

    xml
  end

  # Removes whitespace between nodes.
  #
  def strip_whitespace_between_nodes(xml)
    xml.gsub(/>\s+</, "><")
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
