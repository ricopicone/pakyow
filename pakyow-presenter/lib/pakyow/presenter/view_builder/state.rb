# frozen_string_literal: true

module Pakyow
  module Presenter
    class ViewBuilder
      class State
        include Pakyow::Support::Pipeline::Object

        attr_reader :app, :view

        def initialize(app:, view:)
          @app, @view = app, view
        end
      end
    end
  end
end
