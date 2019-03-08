# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class CleanupUnusedNodes
        def call(renderer)
          unless renderer.rendering_prototype?
            remove_unused_bindings(renderer)
          end

          remove_unused_versions(renderer)
        end

        private

        def remove_unused_bindings(renderer)
          renderer.presenter.view.delegate.each_significant_node(:binding, renderer.presenter.view.object).select { |node|
            !node.labeled?(:used)
          }.each do |node_to_remove|
            renderer.presenter.view.delegate.remove_node(node_to_remove)
          end
        end

        def remove_unused_versions(renderer)
          renderer.presenter.view.delegate.each(renderer.presenter.view.object).select { |node|
            (node.is_a?(StringDoc::Node) && node.significant? && node.labeled?(:version)) && node.label(:version) != VersionedView::DEFAULT_VERSION
          }.each do |node_to_remove|
            renderer.presenter.view.delegate.remove_node(node_to_remove)
          end
        end
      end
    end
  end
end
