module Roadie
  class Document
    attr_reader :html
    attr_accessor :url_options, :asset_providers, :before_inlining, :after_inlining

    def initialize(html)
      @html = html
      @asset_providers = ProviderList.new([FilesystemProvider.new])
      @css = ""
    end

    def add_css(new_css)
      @css << "\n\n" << new_css
    end

    def transform
      # TODO: Fix this mess.
      # TODO: Handle "before" callback
      Inliner.new(Fakeprovider.new(@css), [], html, url_options, after_inlining).execute
    end

    private

    # Used to make the old code work with the new API. This glue will be
    # removed as soon as we don't need it anymore.
    class Fakeprovider
      def initialize(css); @css = css; end
      def all(*); @css; end
    end
  end
end
