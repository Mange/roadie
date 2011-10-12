module Roadie
  # Shortcut for inlining CSS using {Inliner}
  # @see Inliner
  def self.inline_css(*args)
    Roadie::Inliner.new(*args).execute
  end

  # Tries to load the CSS "names" specified in the +targets+ parameter using the Rails asset pipeline.
  #
  # @example
  #   Roadie.load_css(%w[application newsletter])
  #
  # @param [Array<String, Symbol>] targets Stylesheet names - <b>without extensions</b>
  # @return [String] The combined contents of the CSS files
  # @raise [CSSFileNotFound] When a target cannot be found from Rails assets
  def self.load_css(targets)
    targets.map do |file|
      raise CSSFileNotFound, file unless Rails.application.assets[file]
      Rails.application.assets[file].to_s.strip
    end.join("\n")
  end
end

require 'roadie/version'
require 'roadie/css_file_not_found'
require 'roadie/style_declaration'
require 'roadie/inliner'

require 'action_mailer'
require 'roadie/action_mailer_extensions'

ActionMailer::Base.send :include, Roadie::ActionMailerExtensions
