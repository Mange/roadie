module MailStyle
  class CSSFileNotFound < StandardError; end

  def self.inline_css(*args);
    MailStyle::Inlining.new(*args).execute
  end

  def self.load_css(root, targets)
    loaded_css = []
    stylesheets = root.join('public', 'stylesheets')

    targets.map { |target| stylesheets.join("#{target}.css") }.each do |target_file|
      if target_file.exist?
        loaded_css << target_file.read
      else
        raise CSSFileNotFound, "Could not find #{target_file}"
      end
    end
    loaded_css.join("\n")
  end
end

require 'mail_style/inlining'
require 'mail_style/sass_support' if defined?(Sass)

require 'action_mailer'
require 'mail_style/action_mailer_extensions'

ActionMailer::Base.send :include, MailStyle::ActionMailerExtensions
