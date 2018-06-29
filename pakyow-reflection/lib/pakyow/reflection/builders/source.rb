# frozen_string_literal: true

require "pakyow/reflection/builders/abstract"

module Pakyow
  module Reflection
    module Builders
      class Source < Abstract
        def build(type:, options:)
          return if exists?(type)

          @app.source name_for_type(type), adapter: :sql, connection: @app.config.reflection.data.connection do
            primary_id
            timestamps

            options[:attributes].each do |attribute_name, attribute_options|
              attribute attribute_name, attribute_options[:type]
            end

            options[:associations].each do |associated_source|
              has_many associated_source
            end
          end
        end

        private

        def exists?(type)
          name = name_for_type(type)
          @app.state_for(:source).any? { |source|
            source.__class_name.name == name
          }
        end

        def name_for_type(type)
          Support.inflector.pluralize(type).to_sym
        end
      end
    end
  end
end
