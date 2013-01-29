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
      asset_file(name).strip
    end

    private
    
      # If on-the-fly asset compilation is disabled, we must be precompiling assets.
      def assets_precompiled?
        !Rails.configuration.assets.compile rescue false
      end
    
      def asset_file(name)
        basename = remove_prefix(name)
        
        if assets_precompiled?
          # Read the precompiled asset
          asset_path = ActionController::Base.helpers.asset_path(basefile)
          File.read(File.join(Rails.public_path, asset_path))
        else
          # This will compile and return the asset
          Rails.application.assets.find_asset(name).to_s
        end
      end
      end
  end
end
