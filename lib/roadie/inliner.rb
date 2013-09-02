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
      stylesheet.each_inlinable_block do |block|
        dom.css(block.selector.to_s).each do |element|
          style_map.add element, block.properties
        end
      end

      style_map.each_element do |element, rules|
        element["style"] = [rules.to_s, element["style"]].compact.join(";")
      end

      nil
    end

    private
    attr_reader :stylesheet

    def each_element_in_selector(dom, selector)
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

    class StyleMap
      def initialize
        @map = {}
      end

      def add(element, new_properties)
        properties = (@map[element] ||= Rules.empty)
        properties.merge(new_properties)
      end

      def each_element
        @map.each_pair { |element, rules| yield element, rules }
      end
    end

    class Rules
      def self.empty() new([]) end

      def initialize(properties)
        @properties = properties
      end

      def merge(new_properties)
        @properties += new_properties
      end

      def to_s
        sorted_properties.map(&:to_s).join(";")
      end

      protected
      attr_reader :properties

      private
      def sorted_properties
        rules = {}
        properties.sort.each do |property|
          rules[property.property] = property
        end
        rules.values.sort
      end
    end
  end
end
