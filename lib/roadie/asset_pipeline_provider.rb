module Roadie
  # A provider that hooks into Rail's Asset Pipeline.
  #
  # Usage:
  #   config.roadie.provider = AssetPipelineProvider.new
  #
  # @see http://guides.rubyonrails.org/asset_pipeline.html
  class AssetPipelineProvider < AssetProvider
    # The prefix is whatever is prepended to your stylesheets when referenced inside markup.
    #
    # The prefix is stripped away from any URLs before they are looked up in the Asset Pipeline:
    #   find("/assets/posts/comment.css")
    #   # Same as: (if prefix == "/assets"
    #   find("posts/comment.css")
    attr_reader :prefix

    # @param [String] prefix Prefix of assets as seen from the browser
    # @see #prefix
    def initialize(prefix = "/assets")
      super()
      @prefix = prefix
      @quoted_prefix = Regexp.quote(prefix)
    end

    # Looks up the file with the given name in the asset pipeline
    #
    # @return [String] contents of the file
    def find(name)
      asset_file(name).to_s.strip
    end

    private
      def assets
        Roadie.app.assets
      end

      def asset_file(name)
        basename = remove_prefix(name)
        assets[basename].tap do |file|
          raise CSSFileNotFound.new(basename) unless file
        end
      end

      def remove_prefix(name)
        name.sub(/^#{@quoted_prefix}\/?/, '').sub(%r{^/}, '').gsub(%r{//+}, '/')
      end
  end
end
