module Roadie
  class AssetPipelineProvider < AssetProvider
    attr_reader :prefix

    def initialize(prefix = "/assets")
      super()
      @prefix = prefix
      @quoted_prefix = Regexp.quote(prefix)
    end

    def contents_of_file(file)
      asset_file(file).to_s.strip
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
