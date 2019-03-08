# frozen_string_literal: true

module Pakyow
  module Presenter
    class ViewBuilder
      include Support::Pipeline

      action :cleanup_prototype_nodes do |state|
        unless Pakyow.env?(:prototype)
          state.view.delegate.each_significant_node(:prototype, state.view.object).map(&:itself).each(&:remove)
        end
      end

      action :componentize_forms do |state|
        if state.app.config.presenter.componentize
          state.view.delegate.each_significant_node(:form, state.view.object) do |form|
            form.instance_variable_get(:@significance) << :component
            form.attributes[:"data-ui"] = :form
            form.set_label(:component, :form)
          end
        end
      end

      action :componentize_navigator do |state|
        if state.app.config.presenter.componentize
          if html = state.view.delegate.find_first_significant_node(:html, state.view.object)
            html.instance_variable_get(:@significance) << :component
            html.attributes[:"data-ui"] = :navigable
            html.set_label(:component, :navigable)
          end
        end
      end

      action :embed_authenticity, before: :embed_assets do |state|
        if state.app.config.presenter.embed_authenticity_token && head = state.view.delegate.find_first_significant_node(:head, state.view.object)
          # embed the authenticity token
          head.append("<meta name=\"pw-authenticity-token\">")

          # embed the parameter name the token should be submitted as
          head.append("<meta name=\"pw-authenticity-param\">")
        end
      end

      action :create_template_nodes do |state|
        unless Pakyow.env?(:prototype)
          state.view.each_binding_scope do |node_with_binding|
            attributes = node_with_binding.attributes.hash.each_with_object({}) do |(attribute, value), acc|
              acc[attribute] = value if attribute.to_s.start_with?("data")
            end

            state.view.delegate.insert_after_node(node_with_binding, "<script type=\"text/template\"#{StringDoc::Attributes.new(attributes)}>#{state.view.delegate.render(node: node_with_binding)}</script>")
          end
        end
      end

      action :initialize_forms do |state|
        if state.view.object.is_a?(StringDoc::Node) && state.view.form?
          state.view.object.set_label(:metadata, {})
        end

        state.view.forms.each do |form|
          form.object = form.delegate.set_node_label(form.object, :metadata, {})
        end
      end
    end
  end
end
