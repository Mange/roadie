module Roadie
  class StyleProperty
    include Comparable
    attr_reader :property, :value, :important, :specificity

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
