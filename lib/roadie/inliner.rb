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
    # @param [Nokogiri::HTML::Document] dom
    def initialize(stylesheets, dom)
      @stylesheets = stylesheets
      @dom = dom
    end

    # Start the inlining, mutating the DOM tree.
    #
    # @param [true, false] keep_uninlinable_css
    # @param [:root, :head] keep_uninlinable_in
    # @return [nil]
    def inline(keep_uninlinable_css: true, keep_uninlinable_in: :head)
      style_map, extra_blocks = consume_stylesheets

      apply_style_map(style_map)

      if keep_uninlinable_css
        add_uninlinable_styles(keep_uninlinable_in, extra_blocks)
      end

      nil
    end

    protected
    attr_reader :stylesheets, :dom

    private
    def consume_stylesheets
      style_map = StyleMap.new
      extra_blocks = []

      each_style_block do |stylesheet, block|
        if (elements = selector_elements(stylesheet, block))
          style_map.add elements, block.properties
        else
          extra_blocks << block
        end
      end

      [style_map, extra_blocks]
    end

    def each_style_block
      stylesheets.each do |stylesheet|
        stylesheet.blocks.each do |block|
          yield stylesheet, block
        end
      end
    end

    def selector_elements(stylesheet, block)
      block.inlinable? && elements_matching_selector(stylesheet, block.selector)
    end

    def apply_style_map(style_map)
      style_map.each_element { |element, builder| apply_element_style(element, builder) }
    end

    def apply_element_style(element, builder)
      element["style"] = [builder.attribute_string, element["style"]].compact.join(";")
    end

    def elements_matching_selector(stylesheet, selector)
      dom.css(selector.to_s)
    # There's no way to get a list of supported pseudo selectors, so we're left
    # with having to rescue errors.
    # Pseudo selectors that are known to be bad are skipped automatically but
    # this will catch the rest.
    rescue Nokogiri::XML::XPath::SyntaxError, Nokogiri::CSS::SyntaxError => error
      Utils.warn "Cannot inline #{selector.inspect} from \"#{stylesheet.name}\" stylesheet. If this is valid CSS, please report a bug."
      nil
    rescue => error
      Utils.warn "Got error when looking for #{selector.inspect} (from \"#{stylesheet.name}\" stylesheet): #{error}"
      raise unless error.message.include?('XPath')
      nil
    end

    def add_uninlinable_styles(parent, blocks)
      return if blocks.empty?

      parent_node =
        case parent
        when :head
          find_head
        when :root
          dom
        else
          raise ArgumentError, "Parent must be either :head or :root. Was #{parent.inspect}"
        end

      create_style_element(blocks, parent_node)
    end

    def find_head
      dom.at_xpath('html/head')
    end

    def create_style_element(style_blocks, parent)
      return unless parent
      element = Nokogiri::XML::Node.new("style", parent.document)
      element.content = style_blocks.join("\n")
      parent.add_child(element)
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

      def each_element(&block)
        @map.each_pair(&block)
      end
    end
  end
end
