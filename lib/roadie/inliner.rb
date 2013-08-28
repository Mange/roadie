require 'set'
require 'nokogiri'
require 'uri'
require 'css_parser'

module Roadie
  class Inliner
    # @param [Nokogiri::HTML::Document] dom
    def initialize(dom)
      @dom = dom
    end

    # Start the inlining, mutating the DOM tree.
    #
    # @param [String] css
    # @return [nil]
    def inline(css)
      # TODO: Refactor these calls
      @css = css
      inline_css_rules
    end

    private
      attr_reader :css, :dom

      def parsed_css
        CssParser::Parser.new.tap do |parser|
          parser.add_block! clean_css(css) if css
        end
      end

      def inline_css_rules
        elements_with_declarations.each do |element, declarations|
          ordered_declarations = []
          seen_properties = Set.new
          declarations.sort.reverse_each do |declaration|
            next if seen_properties.include?(declaration.property)
            ordered_declarations.unshift(declaration)
            seen_properties << declaration.property
          end

          rules_string = ordered_declarations.map { |declaration| declaration.to_s }.join(';')
          element['style'] = [rules_string, element['style']].compact.join(';')
        end
      end

      def elements_with_declarations
        Hash.new { |hash, key| hash[key] = [] }.tap do |element_declarations|
          parsed_css.each_rule_set do |rule_set|
            each_good_selector(rule_set) do |selector|
              each_element_in_selector(selector) do |element|
                style_declarations_in_rule_set(selector.specificity, rule_set) do |declaration|
                  element_declarations[element] << declaration
                end
              end
            end
          end
        end
      end

      def each_good_selector(rules)
        rules.selectors.each do |selector_string|
          selector = Selector.new(selector_string)
          yield selector if selector.inlinable?
        end
      end

      def each_element_in_selector(selector)
        dom.css(selector.to_s).each do |element|
          yield element
        end
      # There's no way to get a list of supported pseudo rules, so we're left
      # with having to rescue errors.
      # Pseudo selectors that are known to be bad are skipped automatically but
      # this will catch the rest.
      rescue Nokogiri::XML::XPath::SyntaxError, Nokogiri::CSS::SyntaxError => error
        warn "Roadie cannot use #{selector.inspect} when inlining stylesheets"
      rescue => error
        warn "Roadie got error when looking for #{selector.inspect}: #{error}"
        raise unless error.message.include?('XPath')
      end

      def style_declarations_in_rule_set(specificity, rule_set)
        rule_set.each_declaration do |property, value, important|
          yield StyleDeclaration.new(property, value, important, specificity)
        end
      end

      CLEANING_MATCHER = /
        (^\s*             # Beginning-of-lines matches
          (<!\[CDATA\[)|
          (<!--+)
        )|(               # End-of-line matches
          (--+>)|
          (\]\]>)
        $)
      /x.freeze

      def clean_css(css)
        css.gsub(CLEANING_MATCHER, '')
      end
  end
end
