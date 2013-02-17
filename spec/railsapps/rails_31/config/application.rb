require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

if defined?(Bundler)
  Bundler.require(*Rails.groups(:assets => %w(development test)))
end

module Rails31
  class Application < Rails::Application
    config.encoding = "utf-8"
    config.assets.enabled = true
    config.assets.version = '1.0'
    config.action_mailer.default_url_options = {host: 'example.app.org'}
  end
end
