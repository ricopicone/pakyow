# frozen_string_literal: true

class StringDoc
  class MetaNode
    # @api private
    attr_reader :doc, :transforms

    def initialize(nodes)
      nodes.first.parent.replace_node(nodes.first, self)
      nodes[1..-1].each do |node|
        # Remove the node, but don't make it appear to have been removed for transforms.
        #
        node.remove; node.delete_label(:removed)
      end

      @doc = StringDoc.from_nodes(nodes)
      @transforms = { high: [], default: [], low: [] }
    end

    # @api private
    def initialize_copy(_)
      super

      @doc = @doc.dup

      @transforms = Hash[@transforms.map { |key, value|
        [key, value.dup]
      }]
    end

    def next_transform
      @transforms[:high].shift || @transforms[:default].shift || @transforms[:low].shift
    end

    def transform(priority: :default, &block)
      @transforms[priority] << block; block.object_id
    end

    def transforms?
      transforms_itself? || @children.transforms?
    end

    def transforms_itself?
      @transforms[:high].any? || @transforms[:default].any? || @transforms[:low].any?
    end

    # @api private
    def parent=(parent)
      # can safely ignore
    end

    # @api private
    def nodes
      @doc.nodes
    end
  end
end