module Roadie
  class StyleAttributeBuilder
    def initialize
      @styles = []
    end

    def <<(style)
      @styles << style
    end

    def attribute_string
      @styles.sort.map(&:to_s).join(';')
    end
  end
end
