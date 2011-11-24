module Roadie
  # Shortcut for inlining CSS using {Inliner}
  # @see Inliner
  def self.inline_css(*args)
    Roadie::Inliner.new(*args).execute
  end

  # Shortcut to Rails.application.assets
  def self.assets
    Rails.application.assets
  end

  # Tries to load the CSS "names" specified in the +targets+ parameter using the Rails asset pipeline.
  #
  # @example
  #   Roadie.load_css(%w[application newsletter])
  #
  # @param [Array<String|Symbol>] targets Stylesheet names
  # @return [String] The combined contents of the CSS files
  # @raise [CSSFileNotFound] When a target cannot be found from Rails assets
  def self.load_css(targets)
    targets.map do |file|
      raise CSSFileNotFound, file unless assets[file]
      assets[file].to_s.strip
    end.join("\n")
  end
end

require 'roadie/version'
require 'roadie/css_file_not_found'
require 'roadie/style_declaration'
require 'roadie/inliner'

require 'roadie/asset_provider'
require 'roadie/asset_pipeline_provider'

require 'action_mailer'
require 'roadie/action_mailer_extensions'

ActionMailer::Base.send :include, Roadie::ActionMailerExtensions
