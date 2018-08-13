# frozen_string_literal: true

require "pakyow/support/pipelined"

module Pakyow
  module Presenter
    module Pipelines
      module ImplicitRendering
        extend Support::Pipelined::Pipeline

        action :setup_for_implicit_rendering

        protected

        def setup_for_implicit_rendering(connection)
          connection.on :finalize do
            app.subclass(:Renderer).perform_for_connection(self)
          end
        end
      end
    end
  end
end
