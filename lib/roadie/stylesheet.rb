module Roadie
  class Stylesheet
    attr_reader :name, :blocks

    def initialize(name, css)
      @name = name
      @blocks = parse_blocks(css)
    end

    def each_inlinable_block(&block)
      # How unfortunate that Ruby "block" and CSS "block" are colliding here. Pay attention! :-)
      blocks.select(&:inlinable?).map { |style_block|
        [style_block.selector, style_block.properties]
      }.each(&block)
    end

    private
    def parse_blocks(css)
      blocks = []
      setup_parser(css).each_selector do |selector_string, declarations, specificity|
        blocks << StyleBlock.new(
          Selector.new(selector_string, specificity),
          parse_declarations(declarations, specificity)
        )
      end
      blocks
    end

    def setup_parser(css)
      parser = CssParser::Parser.new
      parser.add_block! css
      parser
    end

    def parse_declarations(declarations, specificity)
      declarations.split(';').map { |declaration| StyleProperty.parse(declaration, specificity) }
    end
  end
end
