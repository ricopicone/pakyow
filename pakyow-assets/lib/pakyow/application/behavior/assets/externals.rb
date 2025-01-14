# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/assets/external"

module Pakyow
  class Application
    module Behavior
      module Assets
        module Externals
          extend Support::Extension

          def external_script(name, version = nil, package: nil, files: nil)
            assets_config = if is_a?(Plugin)
              parent.config.assets
            else
              config.assets
            end

            assets_config.externals.scripts << Pakyow::Assets::External.new(
              name, version: version, package: package, files: files, config: assets_config
            )
          end

          apply_extension do
            after "boot", "fetch.assets.externals" do
              if config.assets.externals.pakyow
                external_script :pakyow, "^1.0.0", package: "@pakyow/js", files: [
                  "dist/pakyow.js",
                  "dist/components/confirmable.js",
                  "dist/components/form.js",
                  "dist/components/freshener.js",
                  "dist/components/navigator.js",
                  "dist/components/socket.js",
                  "dist/components/submittable.js"
                ]
              end

              if config.assets.externals.fetch
                fetched = false

                config.assets.externals.scripts.each do |external_script|
                  unless external_script.exist?
                    external_script.fetch!
                    fetched = true
                  end
                end

                if fetched
                  FileUtils.mkdir_p "./tmp"
                  FileUtils.touch "./tmp/restart.txt"
                end
              end
            end
          end
        end
      end
    end
  end
end
