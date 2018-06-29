# frozen_string_literal: true

require "pakyow/framework"
require "pakyow/support/inflector"

require "pakyow/reflection/behavior/config"
require "pakyow/reflection/behavior/reflecting"
require "pakyow/reflection/state"

module Pakyow
  module Reflection
    class Framework < Pakyow::Framework(:reflection)
      def boot
        app.include Behavior::Config
        app.include Behavior::Reflecting
      end
    end
  end
end
