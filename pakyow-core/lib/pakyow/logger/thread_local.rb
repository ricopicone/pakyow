require "forwardable"

require "pakyow/support/deep_freeze"

module Pakyow
  class Logger
    # Determines at log time what logger to use, based on a thread-local context.
    #
    class ThreadLocal
      extend Support::DeepFreeze
      unfreezable :default

      extend Forwardable
      def_delegators :target, :<<, :debug, :error, :fatal, :info, :unknown, :warn, :verbose, :add, :log, :formatter, :level=, :formatter=, :silence

      def initialize(default)
        @default = default
      end

      def target
        Thread.current[:pakyow_logger] || @default
      end
    end
  end
end
