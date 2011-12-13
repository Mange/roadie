# ActionMailer::Base loads the default_url_options on startup via its Railtie
def change_default_url_options(new_options)
  Rails.application.config.action_mailer.default_url_options = new_options
  ActionMailer::Base.default_url_options = new_options
end
