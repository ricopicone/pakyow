# frozen_string_literal: true

require "pakyow/support/inspectable"

class StringDoc
  require "string_doc/attributes"

  class Node
    class << self
      SELF_CLOSING = %w(area base basefont br hr input img link meta).freeze
      FORM_INPUTS  = %w(input select textarea button).freeze
      VALUELESS    = %w(select).freeze

      # Returns true if +tag+ is self-closing.
      #
      def self_closing?(tag)
        SELF_CLOSING.include?(tag)
      end

      # Returns true if +tag+ is a form input.
      #
      def form_input?(tag)
        FORM_INPUTS.include?(tag)
      end

      # Returns true if +tag+ does not contain a value.
      #
      def without_value?(tag)
        VALUELESS.include?(tag)
      end
    end

    include Pakyow::Support::Inspectable
    inspectable :@attributes, :@significance, :@labels

    attr_reader :tag_open_start, :attributes, :tag_open_end, :tag_close, :significance, :labels

    def initialize(tag_open_start = "", attributes = Attributes.new, tag_open_end = "", tag_close = "", significance: [], labels: {})
      @tag_open_start, @attributes, @tag_open_end, @tag_close, @significance, @labels = tag_open_start, attributes, tag_open_end, tag_close, significance, labels
    end

    def initialize_copy(_)
      super

      @attributes = @attributes.dup
      @labels = @labels.dup
    end

    def copy(labels: @labels, attributes: @attributes)
      self.class.allocate.tap do |copy|
        copy.instance_variable_set(:@tag_open_start, @tag_open_start)
        copy.instance_variable_set(:@attributes, attributes)
        copy.instance_variable_set(:@tag_open_end, @tag_open_end)
        copy.instance_variable_set(:@tag_close, @tag_close)
        copy.instance_variable_set(:@labels, labels)
        copy.instance_variable_set(:@significance, @significance)
      end
    end

    def close(tag)
      @tag_open_end = tag ? ">" : ""
      @tag_close = (tag && !self.class.self_closing?(tag)) ? "</#{tag}>" : ""
    end

    def significant?(type = nil)
      if type
        @significance.include?(type.to_sym)
      else
        @significance.any?
      end
    end

    # Returns the value for label with +name+.
    #
    def label(name)
      @labels[name.to_sym]
    end

    # Returns true if label exists with +name+.
    #
    def labeled?(name)
      @labels.key?(name.to_sym)
    end

    # Returns the node's tagname.
    #
    def tagname
      @tag_open_start.gsub(/[^a-zA-Z]/, "")
    end

    def ==(other)
      other.is_a?(Node) &&
        @tag_open_start == other.tag_open_start &&
        @attributes == other.attributes &&
        @tag_open_end == other.tag_open_end &&
        @tag_close == other.tag_close
    end
  end
end
