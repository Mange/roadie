Rails40::Application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.action_mailer.raise_delivery_errors = false
  config.active_support.deprecation = :log

  config.assets.debug = false
  config.assets.compile = false
  config.assets.digest = true
  config.assets.precompile += %w[email.css other.css]
  config.assets.initialize_on_precompile = false
end
