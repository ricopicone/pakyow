# frozen_string_literal: true

module Pakyow
  module Presenter
    class ViewBuilder
      include Support::Pipeline

      action :componentize_forms do |state|
        if state.app.config.presenter.componentize
          state.view.object.each_significant_node(:form) do |form|
            form.instance_variable_get(:@significance) << :component
            form.attributes[:"data-ui"] = :form
            form.set_label(:component, :form)
          end
        end
      end

      action :componentize_navigator do |state|
        if state.app.config.presenter.componentize
          if html = state.view.object.find_first_significant_node(:html)
            html.instance_variable_get(:@significance) << :component
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
    end
  end
end
