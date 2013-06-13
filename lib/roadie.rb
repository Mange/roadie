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

    # Returns the value of +config.roadie.enabled+.
    #
    # Roadie will disable all processing if this config is set to +false+. If
    # you just want to disable CSS inlining without disabling the rest of
    # Roadie, pass +css: nil+ to the +defaults+ method inside your mailers.
    def enabled?
      config.roadie.enabled
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

      if assets_enabled?
        AssetPipelineProvider.new
      else
        FilesystemProvider.new
      end
    end

    # Returns the value of +config.roadie.after_inlining+
    #
    def after_inlining_handler
      config.roadie.after_inlining
    end

    private
      def config
        Roadie.app.config
      end

      def assets_enabled?
        # In Rails 4.0, config.assets.enabled is nil by default, so we need to
        # explicitly make sure it's not false rather than checking for a
        # truthy value.
        config.respond_to?(:assets) and config.assets and config.assets.enabled != false
      end
  end
end

require 'roadie/version'
require 'roadie/css_file_not_found'
require 'roadie/selector'
require 'roadie/style_declaration'

require 'roadie/asset_provider'
require 'roadie/asset_pipeline_provider'
require 'roadie/filesystem_provider'

require 'roadie/inliner'

require 'roadie/railtie' if defined?(Rails)
