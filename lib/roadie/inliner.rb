require 'set'
require 'nokogiri'
require 'uri'
require 'css_parser'

module Roadie
  class Inliner
    # @param [Array<Stylesheet>] stylesheets
    def initialize(stylesheets)
      @stylesheets = stylesheets
    end

    # Start the inlining, mutating the DOM tree.
    #
    # @param [Nokogiri::HTML::Document] dom
    # @return [nil]
    def inline(dom)
      apply style_map(dom)
      nil
    end

    private
    attr_reader :stylesheets

    def apply(style_map)
      style_map.each_element do |element, properties|
        apply_element_style element, properties
      end
    end

    def style_map(dom)
      style_map = StyleMap.new

      each_inlinable_block do |selector, properties|
        elements = elements_matching_selector(selector, dom)
        style_map.add elements, properties
      end

      style_map
    end

    def each_inlinable_block
      stylesheets.each do |stylesheet|
        stylesheet.each_inlinable_block do |selector, properties|
          yield selector, properties
        end
      end
    end

    def apply_element_style(element, properties)
      element["style"] = [properties.to_s, element["style"]].compact.join(";")
    end

    def elements_matching_selector(selector, dom)
      dom.css(selector.to_s)
    # There's no way to get a list of supported pseudo selectors, so we're left
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
        @map = Hash.new { |hash, key|
          hash[key] = StyleProperties.new([])
        }
      end

      def add(elements, new_properties)
        Array(elements).each do |element|
          @map[element].merge!(new_properties)
        end
      end

      def each_element
        @map.each_pair { |element, properties| yield element, properties }
      end
    end
  end
end
