module Roadie
  # Shortcut for inlining CSS using {Inliner}
  # @see Inliner
  def self.inline_css(*args)
    Roadie::Inliner.new(*args).execute
  end

  # Tries to load the CSS "names" specified in the +targets+ parameter inside the +root+ path.
  #
  # @example
  #   Roadie.load_css(Rails.root, %w[application newsletter])
  #
  # @param [Pathname] root The root path of your stylesheets
  # @param [Array<String, Symbol>] targets Stylesheet names - <b>without extensions</b>
  # @return [String] The combined contents of the CSS files
  # @raise [CSSFileNotFound] When a target cannot be found under +[root]/[target].css+
  def self.load_css(root, targets)
    css_files_from_targets(root, targets).map do |file|
      raise CSSFileNotFound, file unless file.exist?
      file.read
    end.join("\n")
  end

  private
    def self.css_files_from_targets(root, targets)
      targets.map { |target| root.join("#{target}.css") }
    end
end

require 'roadie/version'
require 'roadie/css_file_not_found'
require 'roadie/style_declaration'
require 'roadie/inliner'

require 'action_mailer'
require 'roadie/action_mailer_extensions'

ActionMailer::Base.send :include, Roadie::ActionMailerExtensions
