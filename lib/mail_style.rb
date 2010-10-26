module MailStyle
  class CSSFileNotFound < StandardError; end

  def self.inline_css(*args);
    MailStyle::Inlining.new(*args)
  end
end

require 'mail_style/inlining'
require 'mail_style/inline_styles'
require 'mail_style/sass_support' if defined?(Sass)
