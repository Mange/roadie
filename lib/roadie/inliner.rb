# frozen_string_literal: true

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
    # @option options [true, false] :keep_uninlinable_css
    # @option options [:root, :head] :keep_uninlinable_in
    # @option options [true, false] :merge_media_queries
    # @return [nil]
    def inline(options = {})
      keep_uninlinable_css = options.fetch(:keep_uninlinable_css, true)
      keep_uninlinable_in = options.fetch(:keep_uninlinable_in, :head)
      merge_media_queries = options.fetch(:merge_media_queries, true)

      style_map, extra_blocks = consume_stylesheets

      apply_style_map(style_map)

      if keep_uninlinable_css
        add_uninlinable_styles(keep_uninlinable_in, extra_blocks, merge_media_queries)
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

    # Adds unlineable styles in the specified part of the document
    # either the head or in the document
    # @param [Symbol] parent  Where to put the styles
    # @param [Array<StyleBlock>] blocks  Non-inlineable style blocks
    # @param [Boolean]  merge_media_queries  Whether to group media queries
    def add_uninlinable_styles(parent, blocks, merge_media_queries)
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

      create_style_element(blocks, parent_node, merge_media_queries)
    end

    def find_head
      dom.at_xpath('html/head')
    end

    def create_style_element(style_blocks, parent, merge_media_queries)
      return unless parent
      element = Nokogiri::XML::Node.new('style', parent.document)

      element.content =
        if merge_media_queries
          styles_in_shared_media_queries(style_blocks).join("\n")
        else
          styles_in_individual_media_queries(style_blocks).join("\n")
        end
      parent.add_child(element)
    end

    # For performance reasons, we should group styles with the same media types within
    # one media query instead of creating thousands of media queries.
    # https://github.com/artifex404/media-queries-benchmark
    # Example result: ["@media(max-width: 600px) { .col-12 { display: block; } }"]
    # @param {Array<StyleBlock>} style_blocks  Style blocks that could not be inlined
    # @return {Array<String>}
    def styles_in_shared_media_queries(style_blocks)
      style_blocks.group_by(&:media).map do |media_types, blocks|
        css_rules = blocks.map(&:to_s).join("\n")

        if media_types == ['all']
          css_rules
        else
          "@media #{media_types.join(', ')} {\n#{css_rules}\n}"
        end
      end
    end

    # Some users might prefer to not group rules within media queries because
    # it will result in rules getting reordered.
    # e.g.
    # @media(max-width: 600px) { .col-6 { display: block; } }
    # @media(max-width: 400px) { .col-12 { display: inline-block; } }
    # @media(max-width: 600px) { .col-12 { display: block; } }
    # will become
    # @media(max-width: 600px) { .col-6 { display: block; } .col-12 { display: block; } }
    # @media(max-width: 400px) { .col-12 { display: inline-block; } }
    # which would change the styling on the page
    # (before it would've yielded display: block; for .col-12 at max-width: 600px
    # and now it yields inline-block;)
    #
    # If merge_media_queries is set to false,
    # we will generate #{style_blocks.size} media queries, potentially
    # causing performance issues.
    # @param {Array<StyleBlock>} style_blocks  All style blocks
    # @return {Array<String>}
    def styles_in_individual_media_queries(style_blocks)
      style_blocks.map do |css_rule|
        if css_rule.media == ['all']
          css_rule
        else
          "@media #{css_rule.media.join(', ')} {\n#{css_rule}\n}"
        end
      end
    end

    # @api private
    # StyleMap is a map between a DOM element and {StyleAttributeBuilder}. Basically,
    # it's an accumulator for properties, scoped on specific elements.
    class StyleMap
      def initialize
        @map = Hash.new do |hash, key|
          hash[key] = StyleAttributeBuilder.new
        end
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
