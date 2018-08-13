# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/presenter/behavior/config"
require "pakyow/presenter/behavior/error_rendering"
require "pakyow/presenter/behavior/initializing"
require "pakyow/presenter/behavior/watching"

require "pakyow/presenter/helpers/exposures"
require "pakyow/presenter/helpers/rendering"
require "pakyow/presenter/helpers/renderable"

require "pakyow/presenter/pipelines/implicit_rendering"

module Pakyow
  module Presenter
    class Framework < Pakyow::Framework(:presenter)
      def boot
        require "pakyow/presenter/presentable_error"

        app.class_eval do
          subclass!(Renderer)

          stateful :templates, Templates
          stateful :presenter, Presenter
          stateful :binder, Binder
          stateful :processor, Processor

          aspect :presenters
          aspect :binders

          subclass :Connection do
            include Helpers::Renderable
          end

          subclass :Controller do
            include_pipeline Pipelines::ImplicitRendering

            # We don't load these as normal helpers because they should only be
            # available within controllers; not anywhere helpers are loaded.
            #
            include Helpers::Exposures
            include Helpers::Rendering
          end

          before :load do
            # Include other registered helpers into the controller class.
            #
            config.helpers.each do |helper|
              subclass(:Renderer).include helper
            end
          end

          include Behavior::Config
          include Behavior::ErrorRendering
          include Behavior::Initializing
          include Behavior::Watching
        end
      end
    end
  end
end
