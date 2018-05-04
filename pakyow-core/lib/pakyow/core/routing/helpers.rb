# frozen_string_literal: true

require "pakyow/support/safe_string"

module Pakyow
  module Routing
    module Helpers
      include Support::SafeStringHelpers

      def expose(name, default_value = default_omitted = true)
        name = name.to_sym

        value = if block_given?
          yield
        elsif default_omitted
          __send__(name)
        end

        unless default_omitted
          value ||= default_value
        end

        @connection.set(name, value)
      end
    end
  end
end
