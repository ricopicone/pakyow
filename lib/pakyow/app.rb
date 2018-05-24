# frozen_string_literal: true

require "forwardable"

require "pakyow/support/definable"
require "pakyow/support/deep_freeze"
require "pakyow/support/class_state"
require "pakyow/support/inspectable"
require "pakyow/support/hookable"
require "pakyow/support/configurable"
require "pakyow/support/pipelined"

require "pakyow/app/behavior/cookies"
require "pakyow/app/behavior/sessions"
require "pakyow/app/behavior/endpoints"
require "pakyow/app/behavior/pipeline"
require "pakyow/app/behavior/frameworks"
require "pakyow/app/behavior/aspects"
require "pakyow/app/behavior/helpers"
require "pakyow/app/behavior/restarting"

require "pakyow/connection"

module Pakyow
  # Pakyow's main application object. Can be defined directly or subclassed to
  # create multiple application objects, each containing its own state. These
  # applications can then be mounted as an endpoint within the environment.
  #
  #   Pakyow::App.define do
  #     # state shared between all apps goes here
  #   end
  #
  #   class API < Pakyow::App
  #     # state for this app goes here
  #   end
  #
  #   Pakyow.configure do
  #     mount API, at: "/api"
  #   end
  #
  # = Pipeline
  #
  # Requests are received by {App#call}, creating a {Connection} object that
  # provides an interface to the underlying request state. The connection is
  # pushed through a pipeline. Each pipeline action can modify the connection
  # and then either 1) allow the connection to hit the next action 2) halt
  # pipeline execution completely (@see Support::Pipelined).
  #
  # Once the connection exits the pipeline a response is returned. If an action
  # halted, the connection is finalized and returned, otherwise app assumes
  # that the connection was unhandled and returns a canned 404 response.
  #
  # App also catches any unhandled errors that occur in the pipeline by simply
  # logging the error and returning a canned 500 response.
  #
  # = Configuration
  #
  # App objects can be configured.
  #
  #   Pakyow::App.configure do
  #     config.name = "my-app"
  #   end
  #
  # It's possible to configure for certain environments.
  #
  #   Pakyow::App.configure :development do
  #     config.name = "my-dev-app"
  #   end
  #
  # The +app+ config namespace can be extended with your own custom options.
  #
  #   Pakyow::App.configure do
  #     config.foo = "bar"
  #   end
  #
  # Config Options:
  #
  # - +config.name+ defines the name of the application, used when a human
  #   readable unique identifier is necessary. Default is "pakyow".
  #
  # - +config.root+ defines the root directory of the application, relative
  #   to where the environment is started from. Default is +./+.
  #
  # - +config.src+ defines where the application code lives, relative to
  #   where the environment is started from. Default is +{app.root}/app/lib+.
  #
  # - +config.dsl+ determines whether or not objects creation will be exposed
  #   through the simpler dsl.
  #
  # @see Support::Configurable
  #
  # = Hooks
  #
  # The following events can be hooked in to:
  #
  # - initialize
  # - configure
  # - load
  # - freeze
  #
  # Here's how to log a message after initialize:
  #
  #   Pakyow::App.after :initialize do
  #     logger.info "application initialized"
  #   end
  #
  # @see Support::Hookable
  #
  class App
    include Support::Definable
    include Support::Pipelined

    include Support::Configurable

    setting :name, "pakyow"
    setting :root, File.dirname("")

    setting :src do
      File.join(config.root, "backend")
    end

    setting :lib do
      File.join(config.root, "lib")
    end

    setting :dsl, true

    include Support::Hookable
    known_events :initialize, :configure, :load, :finalize, :boot, :rescue

    include Behavior::Cookies
    include Behavior::Sessions
    include Behavior::Endpoints
    include Behavior::Pipeline
    include Behavior::Frameworks
    include Behavior::Aspects
    include Behavior::Helpers
    include Behavior::Restarting

    include Pakyow::Support::Inspectable
    inspectable :environment

    extend Support::DeepFreeze
    unfreezable :builder

    extend Forwardable
    def_delegators :builder, :use

    # The environment the app is running in, e.g. +:development+.
    #
    attr_reader :environment

    # The Rack builder object.
    #
    attr_reader :builder

    def initialize(environment, builder: nil, &block)
      @environment, @builder = environment, builder
      @rescued = false

      performing :initialize do
        performing :configure do
          configure!(environment)
        end

        performing :load do
          $LOAD_PATH.unshift(config.lib)
        end

        # Call the Pakyow::Definable initializer.
        #
        # This ensures that any state registered in the passed block
        # has the proper priority against instance and global state.
        defined!(&block)
      end
    rescue StandardError => error
      rescue!(error)
    end

    # Called by the environment after it boots the app.
    #
    def booted
      unless rescued?
        call_hooks :after, :boot
      end
    rescue StandardError => error
      rescue!(error)
    end

    def call(rack_env)
      begin
        connection = super(Connection.new(self, rack_env))

        if connection.halted?
          connection.finalize
        else
          error_404
        end
      rescue StandardError => error
        rack_env[Rack::RACK_LOGGER].houston(error)
        error_500
      end
    end

    def rescued?
      @rescued == true
    end

    private

    def error_404
      [404, { Rack::CONTENT_TYPE => "text/plain" }, ["404 Not Found"]]
    end

    def error_500
      [500, { Rack::CONTENT_TYPE => "text/plain" }, ["500 Internal Server Error"]]
    end

    # Enter rescue mode, which logs the error and returns an errored response.
    #
    def rescue!(error)
      @rescued = true

      performing :rescue do
        message = <<~ERROR
          #{self.class} failed to initialize.

          #{error.to_s}
          #{error.backtrace.join("\n")}
        ERROR

        Pakyow.logger.error message
        define_singleton_method :call do |_|
          [500, { "Content-Type" => "text/plain" }, [message]]
        end
      end
    end
  end
end