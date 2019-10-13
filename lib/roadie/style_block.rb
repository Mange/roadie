# frozen_string_literal: true

require 'forwardable'

module Roadie
  # @api private
  # A style block is the combination of a {Selector} and a list of {StyleProperty}.
  class StyleBlock
    extend Forwardable
    attr_reader :selector, :properties, :media

    # @param [Selector] selector
    # @param [Array<StyleProperty>] properties
    # @param [Array<String>] media  Array of media types, e.g.
    #                          @media screen, print and (max-width 800px) will become
    #                          ['screen', 'print and (max-width 800px)']
    def initialize(selector, properties, media)
      @selector = selector
      @properties = properties
      @media = media.map(&:to_s)
    end

    # @!method specificity
    #   @see Selector#specificity
    def_delegators :selector, :specificity
    # @!method selector_string
    #   @see Selector#to_s
    def_delegator :selector, :to_s, :selector_string

    # Checks whether the media query can be inlined
    # @see inlineable_media
    # @return {Boolean}
    def inlinable?
      inlinable_media? && selector.inlinable?
    end

    # String representation of the style block. This is valid CSS and can be
    # used in the DOM.
    # @return {String}
    def to_s
      # NB - leave off redundant final semicolon - see https://www.w3.org/TR/CSS2/syndata.html#declaration
      "#{selector}{#{properties.map(&:to_s).join(';')}}"
    end

    private

    # A media query cannot be inlined if it contains any advanced rules
    # e.g. @media only screen {...} is ok to inline but
    # @media only screen and (max-width: 600px) {...} cannot be inlined
    # @return {Boolean}
    def inlinable_media?
      @media.none? { |media_query| media_query.include? '(' }
    end
  end
end
