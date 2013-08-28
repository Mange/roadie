module Roadie
  class << self
    def inline_css(assets, targets, html, url_options, after_inlining_handler = nil)
      document = Document.new(html)
      # Note: Targets are not passed anymore; they are to be removed - all
      # stylesheets should be given explicitly and/or be referenced from the
      # HTML.
      document.asset_providers = [assets]
      document.url_options = url_options
      document.after_inlining = after_inlining_handler
      document.transform
    end

    # Shortcut to Rails.application
    def app
      Rails.application
    end

    # Returns the value of +config.roadie.enabled+.
    #
    # Roadie will disable all processing if this config is set to +false+. If
    # you just want to disable CSS inlining without disabling the rest of
    # Roadie, pass +css: nil+ to the +defaults+ method inside your mailers.
    def enabled?
      config.roadie.enabled
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
  end
end

require 'roadie/version'

require 'roadie/css_not_found'
require 'roadie/invalid_url_path'

require 'roadie/selector'
require 'roadie/style_declaration'

require 'roadie/asset_provider'
require 'roadie/provider_list'
require 'roadie/filesystem_provider'
require 'roadie/null_provider'

require 'roadie/asset_scanner'
require 'roadie/markup_improver'
require 'roadie/url_generator'
require 'roadie/url_rewriter'
require 'roadie/null_url_rewriter'
require 'roadie/inliner'
require 'roadie/document'

require 'roadie/railtie' if defined?(Rails)
