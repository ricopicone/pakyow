# frozen_string_literal: true

require "pakyow/support/class_state"

require "pakyow/reflection/builders/source"
require "pakyow/reflection/builders/resource"
require "pakyow/reflection/builders/endpoints"

module Pakyow
  module Reflection
    module Behavior
      module Config
        extend Support::Extension

        apply_extension do
          settings_for :reflection do
            setting :enabled, false

            setting :builders,
                    source: Builders::Source,
                    resource: Builders::Resource,
                    endpoints: Builders::Endpoints

            setting :ignored_template_stores, [:errors]

            defaults :development do
              setting :enabled, true
            end

            defaults :prototype do
              setting :enabled, true
            end

            settings_for :data do
              setting :connection, :default
            end
          end
        end
      end
    end
  end
end
