# frozen_string_literal: true

require "cgi"

require "pakyow/support/extension"

module Pakyow
  module Realtime
    module Behavior
      module Building
        extend Support::Extension

        apply_extension do
          before :initialize do
            isolated(:ViewBuilder).action :embed_websocket, after: :embed_authenticity do |state|
              if head = state.view.delegate.find_first_significant_node(:head, state.view.object)
                state.view.delegate.append_to_node(
                  head, "<meta name=\"pw-socket\" ui=\"socket\">"
                )
              end
            end
          end
        end
      end
    end
  end
end
