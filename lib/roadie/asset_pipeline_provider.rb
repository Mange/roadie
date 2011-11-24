module Roadie
  # A provider that hooks into Rail's Asset Pipeline.
  #
  # Usage:
  #   config.roadie.provider = AssetPipelineProvider.new('prefix')
  #
  # @see http://guides.rubyonrails.org/asset_pipeline.html
  class AssetPipelineProvider < AssetProvider
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
  end
end
