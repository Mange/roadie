module Roadie
  # Domain object that represents a stylesheet (from disc, perhaps).
  #
  # It has a name and a list of {StyleBlock}s.
  #
  # @attr_reader [String] name the name of the stylesheet ("stylesheets/main.css", "Admin user styles", etc.). The name of the stylesheet will be visible if any errors occur.
  # @attr_reader [Array<StyleBlock>] blocks
  class Stylesheet
    attr_reader :name, :blocks

    # Parses the CSS string into a {StyleBlock}s and stores it.
    #
    # @param [String] name
    # @param [String] css
    def initialize(name, css)
      @name = name
      @blocks = parse_blocks(css)
    end

    # @yield [selector, properties]
    # @yieldparam [Selector] selector
    # @yieldparam [Array<StyleProperty>] properties
    def each_inlinable_block(&block)
      # #map and then #each in order to support chained enumerations, etc. if
      # no block is provided
      inlinable_blocks.map { |style_block|
        [style_block.selector, style_block.properties]
      }.each(&block)
    end

    def to_s
      blocks.join("\n")
    end

    private
    def inlinable_blocks
      blocks.select(&:inlinable?)
    end

    def parse_blocks(css)
      blocks = []
      setup_parser(css).each_selector do |selector_string, declarations, specificity|
        blocks << create_style_block(selector_string, declarations, specificity)
      end
      blocks
    end

    def create_style_block(selector_string, declarations, specificity)
      StyleBlock.new(
        Selector.new(selector_string, specificity),
        parse_declarations(declarations, specificity)
      )
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
