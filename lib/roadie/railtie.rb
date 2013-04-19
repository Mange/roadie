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
  #     config.roadie.custom_converter = lambda do |doc| 
  #       doc.css('#products p.desc a[href^="/"]').each do |link|
  #         link['href'] = "http://www.foo.com" + link['href']
  #       end
  #     end
  #       You can use this to set a custom document converter. When available, 
  #       the document converter is invoked with a Nokogiri document object.
  #
  # @see Roadie
  # @see AssetProvider
  class Railtie < Rails::Railtie
    config.roadie = ActiveSupport::OrderedOptions.new
    config.roadie.enabled = true
    config.roadie.provider = nil
    config.roadie.custom_converter = nil

    initializer "roadie.extend_action_mailer" do
      ActiveSupport.on_load(:action_mailer) do
        include Roadie::ActionMailerExtensions
      end
    end
  end
end
