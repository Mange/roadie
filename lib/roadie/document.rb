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
      # TODO: Fix this mess.
      # TODO: Handle "before" callback
      dom = Nokogiri::HTML.parse html
      Inliner.new(Fakeprovider.new(@css), [], dom, after_inlining).execute
      make_url_rewriter.transform_dom(dom)
      dom.dup.to_html
    end

    def asset_providers=(list)
      @asset_providers = ProviderList.wrap(list)
    end

    private

    # Used to make the old code work with the new API. This glue will be
    # removed as soon as we don't need it anymore.
    class Fakeprovider
      def initialize(css); @css = css; end
      def all(*); @css; end
    end

    def make_url_rewriter
      if url_options
        UrlRewriter.new(UrlGenerator.new(url_options))
      else
        NullUrlRewriter.new
      end
    end
  end
end
