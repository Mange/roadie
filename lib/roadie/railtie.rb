require 'action_mailer'
require 'roadie'
require 'roadie/action_mailer_extensions'

module Roadie
  # {Roadie::Railtie} registers {Roadie} with the current Rails application
  # It adds another configuration option:
  #
  #     config.roadie.provider = nil
  #
  # You can use this to set a provider yourself.
  #
  # @see Roadie
  # @see AssetProvider
  class Railtie < Rails::Railtie
    config.roadie = ActiveSupport::OrderedOptions.new
    config.roadie.provider = nil

    initializer "roadie.extend_action_mailer" do
      ActiveSupport.on_load(:action_mailer) do
        include Roadie::ActionMailerExtensions
      end
    end
  end
end
