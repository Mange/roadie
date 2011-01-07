module Roadie
  def self.inline_css(*args);
    Roadie::Inliner.new(*args).execute
  end

  def self.load_css(root, targets)
    loaded_css = []
    stylesheets = root.join('public', 'stylesheets')

    targets.map { |target| stylesheets.join("#{target}.css") }.each do |target_file|
      if target_file.exist?
        loaded_css << target_file.read
      else
        raise CSSFileNotFound, target_file
      end
    end
    loaded_css.join("\n")
  end
end

require 'roadie/version'
require 'roadie/css_file_not_found'
require 'roadie/inliner'

require 'action_mailer'
require 'roadie/action_mailer_extensions'

ActionMailer::Base.send :include, Roadie::ActionMailerExtensions
