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

    # @param [String] html the input HTML
    def initialize(html)
      @keep_uninlinable_css = true
      @html = html
      @asset_providers = ProviderList.wrap(FilesystemProvider.new)
      @external_asset_providers = ProviderList.empty
      @css = ""
    end

    # Append additional CSS to the document's internal stylesheet.
    # @param [String] new_css
    def add_css(new_css)
      @css << "\n\n" << new_css
    end

    # Transform the input HTML and returns the processed HTML.
    #
    # Before the transformation begins, the {#before_transformation} callback
    # will be called with the parsed HTML tree and the {Document} instance, and
    # after all work is complete the {#after_transformation} callback will be
    # invoked in the same way.
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

      callback before_transformation, dom

      improve dom
      inline dom
      rewrite_urls dom

      callback after_transformation, dom

      # #dup is called since it fixed a few segfaults in certain versions of Nokogiri
      dom.dup.to_html
    end

    # Assign new normal asset providers. The supplied list will be wrapped in a {ProviderList} using {ProviderList.wrap}.
    def asset_providers=(list)
      @asset_providers = ProviderList.wrap(list)
    end

    # Assign new external asset providers. The supplied list will be wrapped in a {ProviderList} using {ProviderList.wrap}.
    def external_asset_providers=(list)
      @external_asset_providers = ProviderList.wrap(list)
    end

    private
    def stylesheet
      Stylesheet.new "(Document styles)", @css
    end

    def improve(dom)
      MarkupImprover.new(dom, html).improve
    end

    def inline(dom)
      dom_stylesheets = AssetScanner.new(dom, asset_providers, external_asset_providers).extract_css
      Inliner.new(dom_stylesheets + [stylesheet], dom).inline(keep_uninlinable_css)
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
  end
end
