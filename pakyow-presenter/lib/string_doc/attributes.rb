# frozen_string_literal: true

require "forwardable"

class StringDoc
  class Attributes
    OPENING = '="'
    CLOSING = '"'
    SPACING = " "

    # @api private
    attr_reader :hash

    extend Forwardable
    def_delegators :@hash, :keys, :each

    def initialize(hash = {})
      @hash = Hash[hash.map { |key, value|
        [key.to_s, value]
      }]
    end

    def initialize_copy(_)
      super

      @hash = Hash[@hash.map { |key, value|
        [key, value.dup]
      }]
    end

    def key?(key)
      @hash.key?(key.to_s)
    end

    def [](key)
      @hash[key.to_s]
    end

    def each_string
      if @hash.empty?
        yield ""
      else
        @hash.each do |name, value|
          yield SPACING
          yield name
          yield OPENING
          yield value.to_s
          yield CLOSING
        end
      end
    end

    def ==(other)
      other.is_a?(Attributes) && @hash == other.hash
    end
  end
end
