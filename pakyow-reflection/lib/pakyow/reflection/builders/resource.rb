# frozen_string_literal: true

require "pakyow/support/core_refinements/string/normalization"

require "pakyow/reflection/builders/abstract"

module Pakyow
  module Reflection
    module Builders
      class Resource < Abstract
        def build(type:, options:)
          return if exists?(type)

          if source = source_for_type(type)
            puts source
            if options[:parents].empty?
              # Define a top level resource.
              #
              define_resource!(@app, type, options)
            else
              # Nest the resource within its parent.
              #
              controller_name = options[:parents].map { |parent_controller_name|
                name_for_type(parent_controller_name)
              }.join("_").to_sym

              local_self = self
              @app.extend_controller controller_name do
                local_self.define_resource!(self, type, options)
              end
            end
          end
        end

        # @api private
        def define_resource!(scope, type, options)
          local_name_for_type = name_for_type(type)
          scope.resources name_for_type(type), path_for_type(type) do
            # TODO: move to a `define_create!` method
            create do
              verify do
                # TODO: if nested, we'll have to explicitly allow `{parent}_id`
                # it'd be nice to allow params defined in the route through always
                #
                # secondarily, it would be nice to expose params[:post_id] as params[:comment][:post_id]
                # only useful for nested...

                required type do
                  options[:attributes].keys.each do |attribute|
                    optional attribute
                  end
                end
              end

              data.send(local_name_for_type).create(params[type])
            end
          end
        end

        private

        def exists?(type)
          name = name_for_type(type)
          @app.state_for(:resource).any? { |source|
            source.__class_name.name == name
          }
        end

        def source_for_type(type)
          @app.state_for(:source).find { |source|
            source.__class_name.name == name_for_type(type)
          }
        end

        def name_for_type(type)
          Support.inflector.pluralize(type).to_sym
        end

        using Support::Refinements::String::Normalization

        def path_for_type(type)
          String.normalize_path(Support.inflector.pluralize(type))
        end
      end
    end
  end
end
