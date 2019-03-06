# frozen_string_literal: true

class StringDoc
  class Node
    module Objects
      class Mutable
        attr_reader :attributes, :children, :labels, :parent, :significance
        attr_writer :children, :parent

        def initialize(node, attributes:, children:, labels:, parent:, significance:)
          @node, @attributes, @children, @labels, @parent, @significance = node, attributes, children, labels, parent, significance
        end

        # Replaces the current node.
        #
        def replace(replacement)
          @parent.replace_node(@node, replacement)
        end

        # Removes the node.
        #
        def remove
          @parent.remove_node(@node)
        end

        # Replaces self's inner html, without making it available for further manipulation.
        #
        def html=(html)
          @children = html.to_s
        end

        # Replaces self's children.
        #
        def replace_children(children)
          @children.replace(children)
        end

        # Removes all children.
        #
        def clear
          @children.clear
        end

        # Inserts +node+ after +self+.
        #
        def after(node)
          @parent.insert_after(node, @node)
        end

        # Inserts +node+ before +self+.
        #
        def before(node)
          @parent.insert_before(node, @node)
        end

        # Appends +node+ as a child.
        #
        def append(node)
          @children.append(node)
        end

        # Prepends +node+ as a child.
        #
        def prepend(node)
          @children.prepend(node)
        end

        # Sets the label with +name+ and +value+.
        #
        def set_label(name, value)
          @labels[name.to_sym] = value
        end

        # Delete the label with +name+.
        #
        def delete_label(name)
          @labels.delete(name.to_sym)
        end
      end
    end
  end
end
