# frozen_string_literal: true

require "delegate"

module Pakyow
  module Presenter
    # Wraps one or more versioned view objects. Provides an interface for manipulating multiple
    # view versions as if they were a single object, picking one to use for presentation.
    #
    class VersionedView < SimpleDelegator
      DEFAULT_VERSION = :default

      def initialize(versions)
        @versions = versions
        determine_working_version
        @used = false
      end

      def initialize_dup(_)
        super

        @versions = @versions.map(&:dup)
        determine_working_version
      end

      def instance
        self.class.allocate.tap do |instance|
          instance.instance_variable_set(:@used, false)
          instance.instance_variable_set(:@versions, @versions.map(&:instance))
          instance.send(:determine_working_version)
        end
      end

      # Returns true if +version+ exists.
      #
      def version?(version)
        !!version_named(version.to_sym)
      end

      # Returns the view matching +version+.
      #
      def versioned(version)
        version_named(version.to_sym)
      end

      # Uses the view matching +version+, removing all other versions.
      #
      def use(version)
        version = version.to_sym
        @used = true

        tap do
          if view = version_named(version)
            view.object = view.delegate.delete_node_label(view.object, :version)
            view.object = view.delegate.set_node_label(view.object, :used, true)
            self.versioned_view = view
            cleanup
          else
            cleanup(:all)
          end
        end
      end

      def transform(object)
        @versions.each do |version|
          version.transform(object)
        end

        yield self, object if block_given?
      end

      def bind(object)
        cleanup

        @versions.each do |version|
          version.bind(object)
        end

        yield self, object if block_given?
      end

      def versioned?
        @versions.length > 1
      end

      def used?
        @used == true
      end

      # Fixes an issue using pp inside a delegator.
      #
      def pp(*args)
        Kernel.pp(*args)
      end

      private

      def cleanup(mode = nil)
        if mode == :all
          @versions.each(&:remove)
          @versions = []
        else
          __getobj__.object = __getobj__.delegate.delete_node_label(__getobj__.object, :version)

          @versions.dup.each do |view_to_remove|
            unless view_to_remove == __getobj__
              view_to_remove.remove
              @versions.delete(view_to_remove)
            end
          end
        end
      end

      def determine_working_version
        self.versioned_view = default_version
      end

      def versioned_view=(view)
        __setobj__(view)
      end

      def default_version
        version_named(DEFAULT_VERSION) || first_version
      end

      def version_named(version)
        @versions.find { |view|
          view.version == version
        }
      end

      def first_version
        @versions[0]
      end
    end
  end
end
