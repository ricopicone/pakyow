# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class PlaceInMode
        def call(renderer)
          mode = renderer.mode

          if mode == :default
            mode = renderer.presenter.view.info(:mode) || mode
          end

          if mode
            mode = mode.to_sym
            renderer.presenter.view.delegate.each_significant_node(:mode, renderer.presenter.view.object).select { |node|
              node.label(:mode) != mode
            }.each do |node_to_remove|
              renderer.presenter.view.delegate.remove_node(node_to_remove)
            end
          end
        end
      end
    end
  end
end
