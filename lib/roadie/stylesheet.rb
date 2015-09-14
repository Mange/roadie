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
    # @deprecated Iterate over the #{blocks} instead. Will be removed on version 4.0.
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
      parser = setup_parser(css)

      parser.each_rule_set do |rule_set, media_types|
        rule_set.selectors.each do |selector_string|
          blocks << create_style_block(selector_string, rule_set)
        end
      end

      blocks
    end

    def create_style_block(selector_string, rule_set)
      specificity = CssParser.calculate_specificity(selector_string)
      selector = Selector.new(selector_string, specificity)
      properties = []

      rule_set.each_declaration do |prop, val, important|
        properties << StyleProperty.new(prop, val, important, specificity)
      end

      StyleBlock.new(selector, properties)
    end

    def setup_parser(css)
      parser = CssParser::Parser.new
      # CssParser::Parser#add_block! mutates input parameter
      parser.add_block! css.dup
      parser
    end
  end
end
