# ActionMailer::Base loads the default_url_options on startup via its Railtie
# so we need to keep the duplicate up-to-date when we change it during runtime
def change_default_url_options(new_options)
  Rails.application.config.action_mailer.default_url_options = new_options
  ActionMailer::Base.default_url_options = new_options
end
