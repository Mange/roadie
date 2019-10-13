# frozen_string_literal: true

module Roadie
  # The main entry point for Roadie. A document represents a working unit and
  # is built with the input HTML and the configuration options you need.
  #
  # A Document must never be used from two threads at the same time. Reusing
  # Documents is discouraged.
  #
  # Stylesheets are added to the HTML from three different sources:
  # 1. Stylesheets inside the document ( +<style>+ elements)
  # 2. Stylesheets referenced by the DOM ( +<link>+ elements)
  # 3. The internal stylesheet (see {#add_css})
  #
  # The internal stylesheet is used last and gets the highest priority. The
  # rest is used in the same order as browsers are supposed to use them.
  #
  # The execution methods are {#transform} and {#transform_partial}.
  #
  # @attr [#call] before_transformation Callback to call just before {#transform}ation begins. Will be called with the parsed DOM tree and the {Document} instance.
  # @attr [#call] after_transformation Callback to call just before {#transform}ation is completed. Will be called with the current DOM tree and the {Document} instance.
  class Document
    attr_reader :html, :asset_providers, :external_asset_providers

    # URL options. If none are given no URL rewriting will take place.
    # @see UrlGenerator#initialize
    attr_accessor :url_options

    attr_accessor :before_transformation, :after_transformation

    # Should CSS that cannot be inlined be kept in a new `<style>` element in `<head>`?
    attr_accessor :keep_uninlinable_css

    # Merge media queries to increase performance and reduce email size if enabled.
    # This will change specificity in some cases, like for example:
    #   @media(max-width: 600px) { .col-6 { display: block; } }
    #   @media(max-width: 400px) { .col-12 { display: inline-block; } }
    #   @media(max-width: 600px) { .col-12 { display: block; } }
    # will become
    #   @media(max-width: 600px) { .col-6 { display: block; } .col-12 { display: block; } }
    #   @media(max-width: 400px) { .col-12 { display: inline-block; } }
    # which would change the styling on the page
    attr_accessor :merge_media_queries

    # The mode to generate markup in. Valid values are `:html` (default) and `:xhtml`.
    attr_reader :mode

    # @param [String] html the input HTML
    def initialize(html)
      @keep_uninlinable_css = true
      @merge_media_queries = true
      @html = html
      @asset_providers = ProviderList.wrap(FilesystemProvider.new)
      @external_asset_providers = ProviderList.empty
      @css = +""
      @mode = :html
    end

    # Append additional CSS to the document's internal stylesheet.
    # @param [String] new_css
    def add_css(new_css)
      @css << "\n\n" << new_css
    end

    # Transform the input HTML as a full document and returns the processed
    # HTML.
    #
    # Before the transformation begins, the {#before_transformation} callback
    # will be called with the parsed HTML tree and the {Document} instance, and
    # after all work is complete the {#after_transformation} callback will be
    # invoked in the same way.
    #
    # Most of the work is delegated to other classes. A list of them can be
    # seen below.
    #
    # @see MarkupImprover MarkupImprover (improves the markup of the DOM)
    # @see Inliner Inliner (inlines the stylesheets)
    # @see UrlRewriter UrlRewriter (rewrites URLs and makes them absolute)
    # @see #transform_partial Transforms partial documents (fragments)
    #
    # @return [String] the transformed HTML
    def transform
      dom = Nokogiri::HTML.parse html

      callback before_transformation, dom

      improve dom
      inline dom, keep_uninlinable_in: :head
      rewrite_urls dom

      callback after_transformation, dom

      remove_ignore_markers dom
      serialize_document dom
    end

    # Transform the input HTML as a HTML fragment/partial and returns the
    # processed HTML.
    #
    # Before the transformation begins, the {#before_transformation} callback
    # will be called with the parsed HTML tree and the {Document} instance, and
    # after all work is complete the {#after_transformation} callback will be
    # invoked in the same way.
    #
    # The main difference between this and {#transform} is that this does not
    # treat the HTML as a full document and does not try to fix it by adding
    # doctypes, {<head>} elements, etc.
    #
    # Most of the work is delegated to other classes. A list of them can be
    # seen below.
    #
    # @see Inliner Inliner (inlines the stylesheets)
    # @see UrlRewriter UrlRewriter (rewrites URLs and makes them absolute)
    # @see #transform Transforms full documents
    #
    # @return [String] the transformed HTML
    def transform_partial
      dom = Nokogiri::HTML.fragment html

      callback before_transformation, dom

      inline dom, keep_uninlinable_in: :root
      rewrite_urls dom

      callback after_transformation, dom

      serialize_document dom
    end

    # Assign new normal asset providers. The supplied list will be wrapped in a {ProviderList} using {ProviderList.wrap}.
    def asset_providers=(list)
      @asset_providers = ProviderList.wrap(list)
    end

    # Assign new external asset providers. The supplied list will be wrapped in a {ProviderList} using {ProviderList.wrap}.
    def external_asset_providers=(list)
      @external_asset_providers = ProviderList.wrap(list)
    end

    # Change the mode. The mode affects how the resulting markup is generated.
    #
    # Valid modes:
    #   `:html` (default)
    #   `:xhtml`
    def mode=(mode)
      if VALID_MODES.include?(mode)
        @mode = mode
      else
        raise ArgumentError, "Invalid mode #{mode.inspect}. Valid modes are: #{VALID_MODES.inspect}"
      end
    end

    private
    VALID_MODES = %i[html xhtml].freeze
    private_constant :VALID_MODES

    def stylesheet
      Stylesheet.new "(Document styles)", @css
    end

    def improve(dom)
      MarkupImprover.new(dom, html).improve
    end

    def inline(dom, options = {})
      keep_uninlinable_in = options.fetch(:keep_uninlinable_in)
      dom_stylesheets = AssetScanner.new(dom, asset_providers, external_asset_providers).extract_css
      Inliner.new(dom_stylesheets + [stylesheet], dom).inline(
        keep_uninlinable_css: keep_uninlinable_css,
        keep_uninlinable_in: keep_uninlinable_in,
        merge_media_queries: merge_media_queries,
      )
    end

    def rewrite_urls(dom)
      make_url_rewriter.transform_dom(dom)
    end

    def serialize_document(dom)
      # #dup is called since it fixed a few segfaults in certain versions of Nokogiri
      save_options = Nokogiri::XML::Node::SaveOptions
      format = {
        html: save_options::AS_HTML,
        xhtml: save_options::AS_XHTML,
      }.fetch(mode)

      dom.dup.to_html(
        save_with: (
          save_options::NO_DECLARATION |
          save_options::NO_EMPTY_TAGS |
          format
        ),
      )
    end

    def make_url_rewriter
      if url_options
        UrlRewriter.new(UrlGenerator.new(url_options))
      else
        NullUrlRewriter.new
      end
    end

    def callback(callable, dom)
      if callable.respond_to?(:call)
        # Arity checking is to support the API without bumping a major version.
        # TODO: Remove on next major version (v4.0)
        if !callable.respond_to?(:parameters) || callable.parameters.size == 1
          callable.(dom)
        else
          callable.(dom, self)
        end
      end
    end

    def remove_ignore_markers(dom)
      dom.css("[data-roadie-ignore]").each do |node|
        node.remove_attribute "data-roadie-ignore"
      end
    end
  end
end
