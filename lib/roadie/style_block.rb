require 'forwardable'

module Roadie
  # A style block is the combination of a selector and a list of properties.
  class StyleBlock
    extend Forwardable
    attr_reader :selector, :properties

    def initialize(selector, properties)
      @selector = selector
      @properties = properties
    end

    def_delegators :selector, :specificity, :inlinable?
    def_delegator :selector, :to_s, :selector_string

    def to_s
      "#{selector}{#{properties.map(&:to_s).join(';')}}"
    end
  end
end
