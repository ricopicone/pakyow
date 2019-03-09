# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class InstallAuthenticity
        def call(renderer)
          renderer.presenter.view.delegate.each_significant_node(:meta, renderer.presenter.view.object) do |node|
            case node.attributes[:name]
            when "pw-authenticity-token"
              renderer.presenter.view.delegate.set_node_attribute(
                node, :content, renderer.connection.verifier.sign(renderer.authenticity_client_id)
              )
            when "pw-authenticity-param"
              renderer.presenter.view.delegate.set_node_attribute(
                node, :content, renderer.connection.app.config.security.csrf.param.to_s
              )
            end
          end
        end
      end
    end
  end
end
