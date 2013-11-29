module Roadie
  class Selector
    def initialize(selector)
      @selector = selector.to_s.strip
    end

    def specificity
      @specificity ||= CssParser.calculate_specificity selector
    end

    def inlinable?
      !(pseudo_element? || at_rule? || pseudo_function?)
    end

    def to_s
      selector
    end

    def to_str() to_s end
    def inspect() selector.inspect end

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
      BAD_PSEUDO_FUNCTIONS = %w[:active :focus :hover :link :target :visited
                                :-ms-input-placeholder :-moz-placeholder
                                :before :after :enabled :disabled :checked].freeze

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
