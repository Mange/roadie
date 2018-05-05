require 'forwardable'

module Roadie
  # @api private
  # A style block is the combination of a {Selector} and a list of {StyleProperty}.
  class StyleBlock
    extend Forwardable
    attr_reader :selector, :properties

    # @param [Selector] selector
    # @param [Array<StyleProperty>] properties
    def initialize(selector, properties, media)
      @selector = selector
      @properties = properties
      @media = media
    end

    # @!method specificity
    #   @see Selector#specificity
    def_delegators :selector, :specificity
    # @!method selector_string
    #   @see Selector#to_s
    def_delegator :selector, :to_s, :selector_string

    # String representation of the style block. This is valid CSS and can be
    # used in the DOM.
    def inlinable?
      inlinable_media? && selector.inlinable?
    end

    def to_s
      "#{selector}{#{properties.map(&:to_s).join(';')}}"
    end

    private

    def inlinable_media?
      @media.all? {|media_query| media_query.to_s.count('()') < 2 }
    end
  end
end
