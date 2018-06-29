# frozen_string_literal: true

module Pakyow
  module Reflection
    # Discovers reflected state for an application.
    #
    # @api private
    class State
      def initialize(app)
        @app = app
      end

      def reflection
        @app.state_for(:templates).reject { |template_store|
          @app.config.reflection.ignored_template_stores.include?(template_store.name)
        }.each_with_object({}) do |template_store, state|
          template_store.paths.each do |view_path|
            discover_view_state(Presenter::View.from_info(template_store.info(view_path)), state)
          end
        end
      end

      def resource_for_type?(type)
        @app.state_for(:controller).any? { |controller|
          controller.path == resource_path_for_type(type)
        }
      end

      def resource_name_for_type(type)
        Support.inflector.pluralize(type).to_sym
      end

      def resource_path_for_type(type)
        "/#{Support.inflector.pluralize(type)}"
      end

      private

      def discover_view_state(view, state = {})
        view.binding_scopes.each do |binding_scope_node|
          binding_scope_view = Presenter::View.from_object(binding_scope_node)

          state[binding_scope_view.binding_name] ||= {
            attributes: {}, associations: [],
            parents: binding_scope_node.label(:binding_path)
          }

          binding_scope_view.binding_props.each do |binding_prop_node|
            binding_prop_view = Presenter::View.from_object(binding_prop_node)
            state[binding_scope_view.binding_name][:attributes][binding_prop_view.binding_name] = {
              type: type_for_binding(binding_prop_view.binding_name)
            }
          end

          binding_scope_view.binding_scopes.each do |nested_binding_scope_node|
            nested_binding_scope_view = Presenter::View.from_object(nested_binding_scope_node)
            (state[binding_scope_view.binding_name][:associations] << nested_binding_scope_view.binding_name).uniq!
          end

          discover_view_state(binding_scope_view, state)
        end
      end

      def type_for_binding(binding_name)
        if binding_name.to_s.end_with?("_at")
          :datetime
        else
          :string
        end
      end
    end
  end
end
