module Roadie
  # Shortcut for inlining CSS using {Inliner}
  # @see Inliner
  def self.inline_css(*args)
    Roadie::Inliner.new(*args).execute
  end

  # Shortcut to Rails.application
  def self.app
    Rails.application
  end

  # Returns all available providers
  def self.providers
    [AssetPipelineProvider, FilesystemProvider]
  end

  # Returns the active provider
  def self.current_provider
    return Roadie.app.config.roadie.provider if Roadie.app.config.roadie.provider

    if Roadie.app.config.assets.enabled
      AssetPipelineProvider.new
    else
      FilesystemProvider.new
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

require 'action_mailer'
require 'roadie/action_mailer_extensions'

require 'roadie/railtie' if defined?(Rails)
