# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Abstract
        def initialize(opts)
          @opts = opts
        end

        def dataset_for_source(_source)
          raise "dataset_for_source is not implemented on #{self}"
        end

        def result_for_attribute_value(attribute, value, source)
          raise "result_for_attribute_value is not implemented on #{self}"
        end

        def connected?
          false
        end

        def migratable?
          false
        end

        module Commands
        end

        module DatasetMethods
          def each(_dataset)
            raise "each is not implemented on #{self}"
          end

          def to_a(_dataset)
            raise "to_a is not implemented on #{self}"
          end

          def one(_dataset)
            raise "one is not implemented on #{self}"
          end

          def count(_dataset)
            raise "count is not implemented on #{self}"
          end
        end
      end
    end
  end
end
