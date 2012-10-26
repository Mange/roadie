require 'action_mailer'
require 'roadie'
require 'roadie/action_mailer_extensions'

module Roadie
  # {Roadie::Railtie} registers {Roadie} with the current Rails application
  # It adds configuration options:
  #
  #     config.roadie.enabled = true
  #       Set this to false to disable Roadie completely. This could be useful if
  #       you don't want Roadie in certain environments.
  #
  #     config.roadie.provider = nil
  #       You can use this to set a provider yourself. See {Roadie::AssetProvider}.
  #
  #
  # @see Roadie
  # @see AssetProvider
  class Railtie < Rails::Railtie
    config.roadie = ActiveSupport::OrderedOptions.new
    config.roadie.enabled = true
    config.roadie.provider = nil

    initializer "roadie.extend_action_mailer" do
      ActiveSupport.on_load(:action_mailer) do
        include Roadie::ActionMailerExtensions
      end
    end
  end
end
