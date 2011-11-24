module Roadie
  class << self
    # Shortcut for inlining CSS using {Inliner}
    # @see Inliner
    def inline_css(*args)
      Roadie::Inliner.new(*args).execute
    end

    # Shortcut to Rails.application
    def app
      Rails.application
    end

    # Returns all available providers
    def providers
      [AssetPipelineProvider, FilesystemProvider]
    end

    # Returns the active provider
    #
    # If no provider has been configured a new provider will be instantiated
    # depending on if the asset pipeline is enabled or not.
    #
    # If +config.assets.enabled+ is +true+, the {AssetPipelineProvider} will be used
    # while {FilesystemProvider} will be used if it is set to +false+.
    #
    # @see AssetPipelineProvider
    # @see FilesystemProvider
    def current_provider
      return config.roadie.provider if config.roadie.provider

      if config.assets.enabled
        AssetPipelineProvider.new
      else
        FilesystemProvider.new
      end
    end

    private
      def config
        Roadie.app.config
      end
  end
end

require 'roadie/version'
require 'roadie/css_file_not_found'
require 'roadie/style_declaration'

require 'roadie/asset_provider'
require 'roadie/asset_pipeline_provider'
require 'roadie/filesystem_provider'

require 'roadie/inliner'

require 'roadie/railtie' if defined?(Rails)
