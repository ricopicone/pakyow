# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Realtime
    module Rendering
      module Actions
        class InstallWebsocket
          def call(renderer)
            if renderer.socket_client_id
              renderer.presenter.view.delegate.each_significant_node(:meta) do |node|
                case node.attributes[:name]
                when "pw-socket"
                  endpoint = renderer.connection.app.config.realtime.endpoint
                  unless endpoint
                    endpoint = if (Pakyow.env?(:development) || Pakyow.env?(:prototype)) && Pakyow.host && Pakyow.port
                      # Connect directly to the app in development, since the proxy does not support websocket connections.
                      #
                      File.join("ws://#{Pakyow.host}:#{Pakyow.port}", renderer.connection.app.config.realtime.path)
                    else
                      File.join("#{renderer.connection.ssl? ? "wss" : "ws"}://#{renderer.connection.request.host_with_port}", renderer.connection.app.config.realtime.path)
                    end
                  end
                  renderer.presenter.view.delegate.set_node_attribute(
                    node, "data-config", "endpoint: #{endpoint}?id=#{renderer.connection.verifier.sign(renderer.socket_client_id)}"
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
