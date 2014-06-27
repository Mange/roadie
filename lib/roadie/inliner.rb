require 'set'
require 'nokogiri'
require 'uri'
require 'css_parser'

module Roadie
  # @api private
  # The Inliner inlines stylesheets to the elements of the DOM.
  #
  # Inlining means that {StyleBlock}s and a DOM tree are combined:
  #   a { color: red; } # StyleBlock
  #   <a href="/"></a>  # DOM
  #
  # becomes
  #
  #   <a href="/" style="color:red"></a>
  class Inliner
    # @param [Array<Stylesheet>] stylesheets the stylesheets to use in the inlining
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
      style_map.each_element do |element, builder|
        apply_element_style element, builder
      end
    end

    def style_map(dom)
      style_map = StyleMap.new

      each_inlinable_block do |stylesheet, selector, properties|
        elements = elements_matching_selector(stylesheet, selector, dom)
        style_map.add elements, properties
      end

      style_map
    end

    def each_inlinable_block
      stylesheets.each do |stylesheet|
        stylesheet.each_inlinable_block do |selector, properties|
          yield stylesheet, selector, properties
        end
      end
    end

    def apply_element_style(element, builder)
      element["style"] = [builder.attribute_string, element["style"]].compact.join(";")
    end

    def elements_matching_selector(stylesheet, selector, dom)
      dom.css(selector.to_s)
    # There's no way to get a list of supported pseudo selectors, so we're left
    # with having to rescue errors.
    # Pseudo selectors that are known to be bad are skipped automatically but
    # this will catch the rest.
    rescue Nokogiri::XML::XPath::SyntaxError, Nokogiri::CSS::SyntaxError => error
      warn "Roadie cannot use #{selector.inspect} (from \"#{stylesheet.name}\" stylesheet) when inlining stylesheets"
      []
    rescue => error
      warn "Roadie got error when looking for #{selector.inspect} (from \"#{stylesheet.name}\" stylesheet): #{error}"
      raise unless error.message.include?('XPath')
      []
    end

    # @api private
    # StyleMap is a map between a DOM element and {StyleAttributeBuilder}. Basically,
    # it's an accumulator for properties, scoped on specific elements.
    class StyleMap
      def initialize
        @map = Hash.new { |hash, key|
          hash[key] = StyleAttributeBuilder.new
        }
      end

      def add(elements, new_properties)
        Array(elements).each do |element|
          new_properties.each do |property|
            @map[element] << property
          end
        end
      end

      def each_element
        @map.each_pair { |element, builder| yield element, builder }
      end
    end
  end
end
