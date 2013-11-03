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

    # Parse a property string.
    #
    # @example
    #   property = Roadie::StyleProperty.parse("color: green")
    #   property.property # => "color"
    #   property.value # => "green"
    #   property.important? # => false
    def self.parse(declaration, specificity)
      allocate.send :read_declaration!, declaration, specificity
    end

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

    protected
    def read_declaration!(declaration, specificity)
      if (matches = DECLARATION_MATCHER.match(declaration))
        initialize matches[:property], matches[:value].strip, !!matches[:important], specificity
        self
      else
        raise UnparseableDeclaration, "Cannot parse declaration #{declaration.inspect}"
      end
    end

    private
    DECLARATION_MATCHER = %r{
      \A\s*
      (?:
        # !important declaration
        (?<property>[^:]+):\s?
        (?<value>.*?)
        (?<important>\s!important)
        ;?
      |
        # normal declaration
        (?<property>[^:]+):\s?
        (?<value>[^;]+)
        ;?
      )
      \s*\Z
    }x.freeze

    def value_with_important
      if important
        "#{value} !important"
      else
        value
      end
    end
  end
end
