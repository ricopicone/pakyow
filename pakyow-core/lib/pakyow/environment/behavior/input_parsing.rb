# frozen_string_literal: true

require "json"

require "pakyow/support/extension"
require "pakyow/support/indifferentize"

require "pakyow/connection/query_parser"
require "pakyow/connection/multipart_parser"

module Pakyow
  module Environment
    module Behavior
      module InputParsing
        extend Support::Extension
        using Support::Indifferentize

        apply_extension do
          class_state :input_parsers, default: {}

          before :configure do
            Pakyow.parse_input "application/x-www-form-urlencoded" do |input, connection|
              connection.params.parse(input.read)
            end

            Pakyow.parse_input "multipart/form-data" do |input, connection|
              Connection::MultipartParser.new(
                connection.params, boundary: connection.type_params[:boundary]
              ).parse(input)
            end

            Pakyow.parse_input "application/json" do |input, connection|
              JSON.parse(input.read).tap do |values|
                if values.is_a?(Hash)
                  values.each do |key, value|
                    if value.is_a?(Hash)
                      value = value.indifferentize
                    end

                    connection.params.add(key, value)
                  end
                end
              end
            end
          end
        end

        class_methods do
          def parse_input(type, &block)
            @input_parsers[type] = block
          end
        end
      end
    end
  end
end