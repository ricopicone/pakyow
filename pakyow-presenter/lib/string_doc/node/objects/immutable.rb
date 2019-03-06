# frozen_string_literal: true

# # frozen_string_literal: true

# require "string_doc/node"

# class StringDoc
#   class Node
#     class Immutable
#       require "string_doc/wrappable"

#       class << self
#         def replace(node, object)
#           object
#         end

#         def remove(_)
#           nil
#         end

#         def set_html(node, object)
#           replace_children(node, unwrap(object))
#         end

#         def replace_children(node, object)
#           object = unwrap(object)
#           children = case object
#           when StringDoc
#             object
#           when Node
#             StringDoc.empty.tap do |doc|
#               doc.nodes << object
#             end
#           else
#             object.to_s
#           end

#           node.copy(children: children)
#         end

#         def clear(node)
#           node.copy(children: "")
#         end

#         def append(node, object)
#           object = unwrap(object)
#           nodes = case object
#           when StringDoc
#             object.nodes
#           when Node
#             [object]
#           else
#             [Node.new(object.to_s)]
#           end

#           node.copy(
#             children: node.children.copy(
#               nodes: node.children.nodes + nodes
#             )
#           )
#         end

#         def prepend(node, object)
#           object = unwrap(object)
#           nodes = case object
#           when StringDoc
#             object.nodes
#           when Node
#             [object]
#           else
#             [Node.new(object.to_s)]
#           end

#           node.copy(
#             children: node.children.copy(
#               nodes: nodes + node.children.nodes
#             )
#           )
#         end

#         def set_label(node, label, value)
#           labels = node.labels.dup
#           labels[label.to_sym] = value
#           node.copy(labels: labels)
#         end

#         def delete_label(node, label)
#           labels = node.labels.dup
#           labels.delete(label.to_sym)
#           node.copy(labels: labels)
#         end

#         private

#         def unwrap(object)
#           while object.respond_to?(:object)
#             object = object.object
#           end

#           object
#         end
#       end

#       attr_reader :object

#       def initialize(object, delegate)
#         @object, @delegate = object, delegate
#       end

#       def initialize_copy(_)
#         @object = @object.dup
#       end

#       ACTIONS = %i(
#         replace remove html= replace_children clear append prepend set_label delete_label parent=
#       ).freeze

#       def after(object)
#         wrap(@object.parent).insert_after(object, @object)
#       end

#       def before(object)
#         wrap(@object.parent).insert_before(object, @object)
#       end

#       include(Wrappable); wrap(Node, self)
#     end
#   end
# end
