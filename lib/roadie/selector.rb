module Roadie
  # @api private
  #
  # A selector is a domain object for a CSS selector, such as:
  #   body
  #   a:hover
  #   input::placeholder
  #   p:nth-of-child(4n+1) .important a img
  #
  # "Selectors" such as "strong, em" are actually two selectors and should be
  # represented as two instances of this class.
  #
  # This class can also calculate specificity for the selector and answer a few
  # questions about them.
  #
  # Selectors can be coerced into Strings, so they should be transparent to use
  # anywhere a String is expected.
  class Selector
    def initialize(selector, specificity = nil)
      @selector = selector.to_s.strip
      @specificity = specificity
    end

    # Returns the specificity of the selector, calculating it if needed.
    def specificity
      @specificity ||= CssParser.calculate_specificity selector
    end

    # Returns whenever or not a selector can be inlined.
    # It's impossible to inline properties that applies to a pseudo element
    # (like +::placeholder+, +::before+) or a pseudo function (like +:active+).
    #
    # We cannot inline styles that appear inside "@" constructs, like +@keyframes+.
    def inlinable?
      !(pseudo_element? || at_rule? || pseudo_function?)
    end

    def to_s() selector end
    def to_str() to_s end
    def inspect() selector.inspect end

    # {Selector}s are equal to other {Selector}s if, and only if, their string
    # representations are equal.
    def ==(other)
      if other.is_a?(self.class)
        other.selector == selector
      else
        super
      end
    end

    protected
    attr_reader :selector

    private
    BAD_PSEUDO_FUNCTIONS = %w[
      :active :focus :hover :link :target :visited
      :-ms-input-placeholder :-moz-placeholder
      :before :after
      :enabled :disabled :checked
    ].freeze

    def pseudo_element?
      selector.include? '::'
    end

    def at_rule?
      selector[0, 1] == '@'
    end

    def pseudo_function?
      BAD_PSEUDO_FUNCTIONS.any? { |bad| selector.include?(bad) }
    end
  end
end
