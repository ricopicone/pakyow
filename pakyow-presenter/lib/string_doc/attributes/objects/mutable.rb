# frozen_string_literal: true

class StringDoc
  class Attributes
    module Objects
      class Mutable
        attr_reader :attributes_hash

        def initialize(attributes_hash)
          @attributes_hash = attributes_hash
        end

        def []=(key, value)
          @attributes_hash[key.to_s] = value
        end

        def replace(attributes_hash)
          @attributes_hash = attributes_hash
        end

        def delete(key)
          @attributes_hash.delete(key.to_s)
        end
      end
    end
  end
end
