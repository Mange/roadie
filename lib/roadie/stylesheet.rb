module Roadie
  class Stylesheet
    attr_reader :name, :blocks

    def initialize(name, css)
      @name = name
      @blocks = parse_blocks(css)
    end

    def each_inlinable_block(&block)
      # How unfortunate that Ruby "block" and CSS "block" are colliding here. Pay attention! :-)
      blocks.select(&:inlinable?).each(&block)
    end

    private
    def parse_blocks(css)
      blocks = []
      parser = CssParser::Parser.new
      parser.add_block! css
      parser.each_selector do |selector_string, declarations, specificity|
        selector = Selector.new(selector_string, specificity)
        properties = declarations.split(';').map { |declaration| StyleProperty.parse(declaration, specificity) }
        blocks << StyleBlock.new(selector, properties)
      end
      blocks
    end
  end
end
