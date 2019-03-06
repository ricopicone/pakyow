# frozen_string_literal: true

module Pakyow
  module Presenter
    class ViewBuilder
      include Support::Pipeline

      action :cleanup_prototype_nodes do |state|
        unless Pakyow.env?(:prototype)
          state.view.object.each_significant_node(:prototype).map(&:itself).each(&:remove)
        end
      end

      action :componentize_forms do |state|
        if state.app.config.presenter.componentize
          state.view.object.each_significant_node(:form) do |form|
            form.significance << :component
            form.attributes[:"data-ui"] = :form
            form.set_label(:component, :form)
          end
        end
      end

      action :componentize_navigator do |state|
        if state.app.config.presenter.componentize
          if html = state.view.object.find_first_significant_node(:html)
            html.significance << :component
            html.attributes[:"data-ui"] = :navigable
            html.set_label(:component, :navigable)
          end
        end
      end

      action :embed_authenticity, before: :embed_assets do |state|
        if state.app.config.presenter.embed_authenticity_token && head = state.view.object.find_first_significant_node(:head)
          # embed the authenticity token
          head.append("<meta name=\"pw-authenticity-token\">")

          # embed the parameter name the token should be submitted as
          head.append("<meta name=\"pw-authenticity-param\">")
        end
      end

      action :create_template_nodes do |state|
        unless Pakyow.env?(:prototype)
          state.view.each_binding_scope do |node_with_binding|
            attributes = node_with_binding.attributes.attributes_hash.each_with_object({}) do |(attribute, value), acc|
              acc[attribute] = value if attribute.to_s.start_with?("data")
            end

            node_with_binding.after("<script type=\"text/template\"#{StringDoc::Attributes.new(attributes)}>#{node_with_binding}</script>")
          end
        end
      end

      action :initialize_forms do |state|
        if state.view.object.is_a?(StringDoc::Node) && state.view.form?
          state.view.object.set_label(:metadata, {})
        end

        state.view.forms.each do |form|
          form.object.set_label(:metadata, {})
        end
      end

      # def forms(renderer)
      #     [].tap do |forms|
      #       if renderer.presenter.view.object.is_a?(StringDoc::Node) && renderer.presenter.view.form?
      #         forms << renderer.presenter.presenter_for(
      #           renderer.presenter.view, type: FormPresenter
      #         )
      #       end

      #       forms.concat(renderer.presenter.forms)
      #     end
      #   end

      #   def init_form_metadata(form)
      #     unless form.view.labeled?(:metadata)
      #       form.view.object.set_label(:metadata, {})
      #     end
      #   end
    end
  end
end
