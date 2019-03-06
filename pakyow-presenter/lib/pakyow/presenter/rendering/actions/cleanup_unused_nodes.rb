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
          renderer.presenter.view.object.each_significant_node(:binding).select { |node|
            !node.labeled?(:used)
          }.each(&:remove)
        end

        def remove_unused_versions(renderer)
          renderer.presenter.view.object.each.select { |node|
            (node.is_a?(StringDoc::Node) && node.significant? && node.labeled?(:version)) && node.label(:version) != VersionedView::DEFAULT_VERSION
          }.each(&:remove)
        end
      end
    end
  end
end
