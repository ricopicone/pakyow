# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Sql
        class Differ
          def initialize(connection:, source:, attributes: source.attributes)
            @connection, @source, @attributes = connection, source, attributes
          end

          def exists?
            if logger = @connection.logger
              # This method causes a sql error if the table doesn't exist, which can be confusing when
              # included in the log output. Silence even errors just for this one check.
              #
              logger.silence(Logger::ERROR + 1) do
                raw_connection.table_exists?(table_name)
              end
            else
              raw_connection.table_exists?(table_name)
            end
          end

          def changes?
            attributes_to_add.any? || columns_to_remove.any? || column_types_to_change.any?
          end

          def table_name
            @source.dataset_table
          end

          def attributes
            Hash[@attributes.map { |attribute_name, attribute|
              [attribute_name, @connection.adapter.finalized_attribute(attribute)]
            }]
          end

          def attributes_to_add
            {}.tap { |attributes|
              self.attributes.each do |attribute_name, attribute_type|
                unless schema.find { |column| column[0] == attribute_name }
                  attributes[attribute_name] = attribute_type
                end
              end
            }
          end

          def columns_to_remove
            {}.tap { |columns|
              schema.each do |column_name, column_info|
                unless @source.attributes.keys.find { |attribute_name| attribute_name == column_name }
                  columns[column_name] = column_info
                end
              end
            }
          end

          def column_types_to_change
            {}.tap { |attributes|
              self.attributes.each do |attribute_name, attribute_type|
                if found_column = schema.find { |column| column[0] == attribute_name }
                  column_name, column_info = found_column
                  unless column_info[:type] == attribute_type.meta[:column_type] && (!attribute_type.meta.include?(:native_type) || column_info[:db_type] == attribute_type.meta[:native_type])
                    attributes[column_name] = attribute_type.meta[:migration_type]
                  end
                end
              end
            }
          end

          private

          def raw_connection
            @connection.adapter.connection
          end

          def schema
            raw_connection.schema(table_name)
          end
        end
      end
    end
  end
end
