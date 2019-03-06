# frozen_string_literal: true

# # frozen_string_literal: true

# require "string_doc/attributes"

# class StringDoc
#   class Attributes
#     class Immutable
#       require "string_doc/wrappable"

#       class << self
#         def set(attributes, key, value)
#           attributes_hash = attributes.attributes_hash.dup
#           attributes_hash[key.to_s] = value
#           attributes.copy(attributes_hash: attributes_hash)
#         end

#         def delete(attributes, key)
#           attributes_hash = attributes.attributes_hash.dup
#           attributes_hash.delete(key.to_s)
#           attributes.copy(attributes_hash: attributes_hash)
#         end
#       end

#       attr_reader :object

#       def initialize(object, delegate)
#         @object, @delegate = object, delegate
#       end

#       ACTIONS = %i(
#         []= delete
#       ).freeze

#       include(Wrappable); wrap(Attributes, self)
#     end
#   end
# end
