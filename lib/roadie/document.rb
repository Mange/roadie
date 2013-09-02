module Roadie
  class Document
    attr_reader :html, :asset_providers
    attr_accessor :url_options, :before_inlining, :after_inlining

    def initialize(html)
      @html = html
      @asset_providers = ProviderList.wrap(FilesystemProvider.new)
      @css = ""
    end

    def add_css(new_css)
      @css << "\n\n" << new_css
    end

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

    def asset_providers=(list)
      @asset_providers = ProviderList.wrap(list)
    end

    private
    def improve(dom)
      MarkupImprover.new(dom, html).improve
    end

    def inline(dom)
      document_styles = AssetScanner.new(dom, asset_providers).extract_css
      css = [document_styles, @css].flatten.join("\n")
      Inliner.new(css).inline(dom)
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
