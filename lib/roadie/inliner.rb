require 'set'
require 'nokogiri'
require 'uri'
require 'css_parser'

module Roadie
  class Inliner
    # @param [String] css
    def initialize(css)
      # TODO: Pass a list of Stylesheet rather than raw CSS
      @stylesheet = Stylesheet.new("unnamed", css)
    end

    # Start the inlining, mutating the DOM tree.
    #
    # @param [Nokogiri::HTML::Document] dom
    # @return [nil]
    def inline(dom)
      style_map = StyleMap.new

      stylesheet.each_inlinable_block do |selector, properties|
        style_map.add_elements elements_in_selector(selector, dom), properties
      end

      style_map.each_element do |element, rules|
        apply_element_style element, rules
      end

      nil
    end

    private
    attr_reader :stylesheet

    def apply_element_style(element, rules)
      element["style"] = [rules.to_s, element["style"]].compact.join(";")
    end

    def elements_in_selector(selector, dom)
      dom.css(selector.to_s)
    # There's no way to get a list of supported pseudo rules, so we're left
    # with having to rescue errors.
    # Pseudo selectors that are known to be bad are skipped automatically but
    # this will catch the rest.
    rescue Nokogiri::XML::XPath::SyntaxError, Nokogiri::CSS::SyntaxError => error
      warn "Roadie cannot use #{selector.inspect} when inlining stylesheets"
      []
    rescue => error
      warn "Roadie got error when looking for #{selector.inspect}: #{error}"
      raise unless error.message.include?('XPath')
      []
    end

    class StyleMap
      def initialize
        @map = {}
      end

      def add_elements(elements, new_properties)
        elements.each { |element| add(element, new_properties) }
      end

      def add(element, new_properties)
        properties = (@map[element] ||= StyleProperties.new([]))
        properties.merge!(new_properties)
      end

      def each_element
        @map.each_pair { |element, rules| yield element, rules }
      end
    end
  end
end
