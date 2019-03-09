# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Building
        extend Support::Extension

        apply_extension do
          before :initialize do
            isolated(:ViewBuilder).action :embed_assets do |state|
              if head = state.view.head
                state.app.packs(state.view).each do |pack|
                  if pack.javascripts?
                    state.view.delegate.append_to_node(
                      head.object, "<script src=\"#{pack.public_path}.js\"></script>\n"
                    )
                  end

                  if pack.stylesheets?
                    state.view.delegate.append_to_node(
                      head.object, "<link rel=\"stylesheet\" type=\"text/css\" media=\"all\" href=\"#{pack.public_path}.css\">\n"
                    )
                  end
                end
              end
            end
          end
        end

        # @api private
        def packs(view)
          (autoloaded_packs + view_packs(view) + component_packs(view)).uniq.each_with_object([]) { |pack_name, packs|
            if found_pack = state(:pack).find { |pack| pack.name == pack_name.to_sym }
              packs << found_pack
            end
          }
        end

        # @api private
        def autoloaded_packs
          config.assets.packs.autoload
        end

        # @api private
        def view_packs(view)
          view.info(:packs).to_a
        end

        # @api private
        def component_packs(view)
          view.delegate.each_significant_node(:component).map { |node|
            node.label(:component)
          }
        end
      end
    end
  end
end
