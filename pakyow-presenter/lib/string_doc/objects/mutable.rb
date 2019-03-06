# frozen_string_literal: true

class StringDoc
  module Objects
    class Mutable
      attr_reader :nodes

      def initialize(nodes)
        @nodes = nodes
      end

      # Clears all nodes.
      #
      def clear
        @nodes.clear
      end
      alias remove clear

      # Replaces the current document.
      #
      # Accepts a +StringDoc+ or XML +String+.
      #
      def replace(doc_or_string)
        @nodes = nodes_from_doc_or_string(doc_or_string)
      end

      # Appends to this document.
      #
      # Accepts a +StringDoc+ or XML +String+.
      #
      def append(doc_or_string)
        @nodes.concat(nodes_from_doc_or_string(doc_or_string))
      end

      # Prepends to this document.
      #
      # Accepts a +StringDoc+ or XML +String+.
      #
      def prepend(doc_or_string)
        @nodes.unshift(*nodes_from_doc_or_string(doc_or_string))
      end

      # Inserts a node after another node contained in this document.
      #
      def insert_after(node_to_insert, after_node)
        if after_node_index = @nodes.index(after_node)
          @nodes.insert(after_node_index + 1, *nodes_from_doc_or_string(node_to_insert))
        end
      end

      # Inserts a node before another node contained in this document.
      #
      def insert_before(node_to_insert, before_node)
        if before_node_index = @nodes.index(before_node)
          @nodes.insert(before_node_index, *nodes_from_doc_or_string(node_to_insert))
        end
      end

      # Removes a node from the document.
      #
      def remove_node(node_to_delete)
        @nodes.delete_if { |node|
          node.object_id == node_to_delete.object_id
        }
      end

      # Replaces a node from the document.
      #
      def replace_node(node_to_replace, replacement_node)
        if replace_node_index = @nodes.index(node_to_replace)
          nodes_to_insert = nodes_from_doc_or_string(replacement_node).map { |node|
            node.parent = self; node
          }
          @nodes.insert(replace_node_index + 1, *nodes_to_insert)
          @nodes.delete_at(replace_node_index)
        end
      end

      private

      def nodes_from_doc_or_string(doc_node_or_string)
        case doc_node_or_string
        when StringDoc
          doc_node_or_string.nodes
        when Node
          [doc_node_or_string]
        else
          StringDoc.new(doc_node_or_string.to_s, type: :mutable).nodes
        end
      end
    end
  end
end
