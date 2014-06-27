require 'forwardable'

module Roadie
  # @api private
  # A style block is the combination of a {Selector} and a list of {StyleProperty}.
  class StyleBlock
    extend Forwardable
    attr_reader :selector, :properties

    # @param [Selector] selector
    # @param [Array<StyleProperty>] properties
    def initialize(selector, properties)
      @selector = selector
      @properties = properties
    end

    # @!method specificity
    #   @see Selector#specificity
    # @!method inlinable?
    #   @see Selector#inlinable?
    def_delegators :selector, :specificity, :inlinable?
    # @!method selector_string
    #   @see Selector#to_s
    def_delegator :selector, :to_s, :selector_string

    # String representation of the style block. This is valid CSS and can be
    # used in the DOM.
    def to_s
      "#{selector}{#{properties.map(&:to_s).join(';')}}"
    end
  end
end
