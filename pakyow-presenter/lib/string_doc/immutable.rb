# frozen_string_literal: true

require "string_doc"

class StringDoc
  class Immutable
    require "string_doc/node/immutable"
    require "string_doc/attributes/immutable"
    require "string_doc/wrappable"

    class << self
      def clear(doc)
        doc.copy(nodes: [])
      end
      alias remove clear

      def replace(doc, object)
        object = unwrap(object)

        case object
        when StringDoc
          doc.copy(nodes: object.nodes)
        when Node
          doc.copy(nodes: [object])
        else
          doc.copy(collapsed: object.to_s, nodes: [])
        end
      end

      def append(doc, object)
        object = unwrap(object)

        case object
        when StringDoc
          doc.copy(nodes: doc.nodes + object.nodes)
        when Node
          doc.copy(nodes: doc.nodes + [object])
        else
          doc.copy(nodes: doc.nodes + [Node.new(object.to_s)])
        end
      end

      def prepend(doc, object)
        object = unwrap(object)

        case object
        when StringDoc
          doc.copy(nodes: object.nodes + doc.nodes)
        when Node
          doc.copy(nodes: [object] + doc.nodes)
        else
          doc.copy(nodes: [Node.new(object.to_s)] + doc.nodes)
        end
      end

      def insert_after(doc, object, node)
        object, node = unwrap(object), unwrap(node)
        if index = doc.nodes.index(node)
          case object
          when StringDoc
            doc.copy(nodes: doc.nodes.dup.insert(index + 1, *object.nodes))
          when Node
            doc.copy(nodes: doc.nodes.dup.insert(index + 1, object))
          else
            doc.copy(nodes: doc.nodes.dup.insert(index + 1, Node.new(object.to_s)))
          end
        end
      end

      def insert_before(doc, object, node)
        object, node = unwrap(object), unwrap(node)
        if index = doc.nodes.index(node)
          case object
          when StringDoc
            doc.copy(nodes: doc.nodes.dup.insert(index, *object.nodes))
          when Node
            doc.copy(nodes: doc.nodes.dup.insert(index, object))
          else
            doc.copy(nodes: doc.nodes.dup.insert(index, Node.new(object.to_s)))
          end
        end
      end

      def remove_node(doc, node)
        node = unwrap(node)
        nodes = doc.nodes.dup
        nodes.delete_if { |doc_node|
          doc_node.object_id == node.object_id
        }

        doc.copy(nodes: nodes)
      end

      def replace_node(doc, node, object)
        node, object = unwrap(node), unwrap(object)
        if index = doc.nodes.index(node)
          nodes = case object
          when StringDoc
            object.nodes
          when Node
            [object]
          else
            [Node.new(object.to_s)]
          end

          doc_nodes = doc.nodes.dup
          doc_nodes.insert(index + 1, *nodes)
          doc_nodes.delete_at(index)
          doc.copy(nodes: doc_nodes)
        end
      end

      private

      def unwrap(object)
        while object.respond_to?(:object)
          object = object.object
        end

        object
      end
    end

    attr_reader :object

    def initialize(object, delegate = self)
      @object, @delegate = object, delegate

      if @delegate === self
        @transformations = {}
      end
    end

    def transform(object, &block)
      (@transformations[object] ||= []) << block
    end

    def render(doc = @object, output: String.new)
      if doc.collapsed && doc.empty?
        output << doc.collapsed
      else
        if transformations = @transformations.delete(doc)
          transformations.each do |transformation|
            doc = instance_exec(doc, &transformation)

            if doc.nil?
              return
            elsif doc.is_a?(String)
              break
            end
          end

          return render(doc, output: output)
        end

        doc.nodes.each do |node|
          write_node_to_output(node, output)
        end
      end

      output
    end
    alias to_html render
    alias to_s render

    ACTIONS = %i(
      clear remove replace append prepend insert_after insert_before remove_node replace_node
    ).freeze

    include(Wrappable); wrap(StringDoc, self)

    private

    def write_node_to_output(node, output)
      case node
      when StringDoc::Node
        if transformations = @transformations.delete(node)
          transformations.each do |transformation|
            node = instance_exec(node, &transformation)

            if node.nil?
              return
            elsif node.is_a?(String)
              break
            end
          end

          return write_node_to_output(node, output)
        end

        output << node.tag_open_start

        attributes = node.attributes
        if transformations = @transformations.delete(attributes)
          transformations.each do |transformation|
            attributes = instance_exec(attributes, &transformation)
          end
        end

        attributes.each_string do |attribute_string|
          output << attribute_string
        end

        output << node.tag_open_end

        case node.children
        when StringDoc
          render(node.children, output: output)
        else
          output << node.children
        end

        output << node.tag_close
      else
        output << node.to_s
      end
    end
  end
end
