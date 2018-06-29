# frozen_string_literal: true

require "pakyow/support/class_state"

module Pakyow
  module Reflection
    module Behavior
      module Reflecting
        extend Support::Extension

        apply_extension do
          after :boot, priority: :high do
            if config.reflection.enabled
              begin
                State.new(self).reflection.each do |type, options|
                  config.reflection.builders.values.each do |builder|
                    builder.new(self).build(type: type, options: options)
                  end
                end
              rescue StandardError => error
                puts "Failed to generate reflection: #{error.message}"
                puts error.backtrace.join("\n")

                # TODO: enable this:
                # Pakyow.logger.error "Failed to generate reflection: #{error.message}"
                # Pakyow.logger.error error.backtrace.join("\n")
              end
            end
          end
        end
      end
    end
  end
end
