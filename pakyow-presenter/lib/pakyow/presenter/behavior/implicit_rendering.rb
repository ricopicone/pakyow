# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      # Performs a render if a controller is called but doesn't explicitly render.
      #
      module ImplicitRendering
        extend Support::Extension

        prepend_methods do
          def dispatch
            super

            connection.app.isolated(:ViewRenderer).perform_for_connection(connection)
          end
        end
      end
    end
  end
end