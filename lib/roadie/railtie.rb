module Roadie
  class Railtie < Rails::Railtie
    config.roadie = ActiveSupport::OrderedOptions.new
    config.roadie.provider = nil

    initializer "roadie.extend_action_mailer" do
      ActionMailer::Base.send :include, Roadie::ActionMailerExtensions
    end
  end
end
