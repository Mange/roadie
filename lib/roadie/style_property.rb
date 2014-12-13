module Roadie
  # @api private
  # Domain object for a CSS property such as "color: red !important".
  #
  # @attr_reader [String] property name of the property (such as "font-size").
  # @attr_reader [String] value value of the property (such as "5px solid green").
  # @attr_reader [Boolean] important if the property is "!important".
  # @attr_reader [Integer] specificity specificity of parent {Selector}. Used to compare/sort.
  class StyleProperty
    include Comparable

    attr_reader :value, :important, :specificity

    # @todo Rename #property to #name
    attr_reader :property

    def initialize(property, value, important, specificity)
      @property = property
      @value = value
      @important = important
      @specificity = specificity
    end

    def important?
      @important
    end

    # Compare another {StyleProperty}. Important styles are "greater than"
    # non-important ones; otherwise the specificity declares order.
    def <=>(other)
      if important == other.important
        specificity <=> other.specificity
      else
        important ? 1 : -1
      end
    end

    def to_s
      [property, value_with_important].join(':')
    end

    def inspect
      "#{to_s} (#{specificity})"
    end

    private
    def value_with_important
      if important
        "#{value} !important"
      else
        value
      end
    end
  end
end
