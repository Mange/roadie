module Roadie
  class StyleDeclaration
    include Comparable
    attr_reader :property, :value, :important, :specificity

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
      [property, value].join(':')
    end

    def inspect
      extra = [important ? '!important' : nil, specificity].compact
      "#{to_s} (#{extra.join(' , ')})"
    end
  end
end
