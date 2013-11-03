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
  # @attr [#call] before_inlining Callback to call just before {#transform}ation is begun. Will be called with the parsed DOM tree.
  # @attr [#call] after_inlining Callback to call just before {#transform}ation is completed. Will be called with the current DOM tree.
  class Document
    attr_reader :html, :asset_providers

    # URL options. If none are given no URL rewriting will take place.
    # @see UrlGenerator#initialize
    attr_accessor :url_options

    attr_accessor :before_inlining, :after_inlining

    # @param [String] html the input HTML
    def initialize(html)
      @html = html
      @asset_providers = ProviderList.wrap(FilesystemProvider.new)
      @css = ""
    end

    # Append additional CSS to the document's internal stylesheet.
    # @param [String] new_css
    def add_css(new_css)
      @css << "\n\n" << new_css
    end

    # Transform the input HTML and returns the processed HTML.
    #
    # Before the transformation begins, the {#before_inlining} callback will be
    # called with the parsed HTML tree, and after all work is complete the
    # {#after_inlining} callback will be invoked.
    #
    # Most of the work is delegated to other classes. A list of them can be seen below.
    #
    # @see MarkupImprover MarkupImprover (improves the markup of the DOM)
    # @see Inliner Inliner (inlines the stylesheets)
    # @see UrlRewriter UrlRewriter (rewrites URLs and makes them absolute)
    #
    # @return [String] the transformed HTML
    def transform
      dom = Nokogiri::HTML.parse html

      callback before_inlining, dom

      improve dom
      inline dom
      rewrite_urls dom

      callback after_inlining, dom

      # #dup is called since it fixed a few segfaults in certain versions of Nokogiri
      dom.dup.to_html
    end

    # Assign new asset providers. The supplied list will be wrapped in a {ProviderList} using {ProviderList.wrap}.
    def asset_providers=(list)
      @asset_providers = ProviderList.wrap(list)
    end

    private
    def stylesheet
      Stylesheet.new "(Document styles)", @css
    end

    def improve(dom)
      MarkupImprover.new(dom, html).improve
    end

    def inline(dom)
      dom_stylesheets = AssetScanner.new(dom, asset_providers).extract_css
      Inliner.new(dom_stylesheets + [stylesheet]).inline(dom)
    end

    def rewrite_urls(dom)
      make_url_rewriter.transform_dom(dom)
    end

    def make_url_rewriter
      if url_options
        UrlRewriter.new(UrlGenerator.new(url_options))
      else
        NullUrlRewriter.new
      end
    end

    def callback(callable, dom)
      callable.(dom) if callable.respond_to?(:call)
    end
  end
end
