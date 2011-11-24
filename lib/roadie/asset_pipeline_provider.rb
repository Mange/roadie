module Roadie
  class AssetPipelineProvider < AssetProvider
    def initialize(path_prefix = "/assets")
      super()
      @path_prefix = path_prefix
    end

    def find_asset_from_url(url)
      asset_filename = url.path.sub(/^#{Regexp.quote(@path_prefix)}/, '').gsub(%r{^/|//+}, '')
      Roadie.assets[asset_filename].tap do |asset|
        raise CSSFileNotFound.new(asset_filename, url) unless asset
      end
    end
  end
end
