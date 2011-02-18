require 'uri'
require 'nokogiri'
require 'css_parser'

module Roadie
  # This module adds the Roadie functionality to ActionMailer 3 when included in ActionMailer::Base.
  #
  # If you want to add Roadie to any other mail framework, take a look at how this module is implemented.
  module ActionMailerExtensions
    def self.included(base)
      base.class_eval do
        alias_method_chain :collect_responses_and_parts_order, :inline_styles
        alias_method_chain :mail, :inline_styles
      end
    end

    protected
      def mail_with_inline_styles(headers = {}, &block)
        @inline_style_css_targets = headers[:css]
        mail_without_inline_styles(headers, &block).tap do |email|
          email.header.fields.delete_if { |field| field.name == 'css' }
        end
      end

      def collect_responses_and_parts_order_with_inline_styles(headers, &block)
        responses, order = collect_responses_and_parts_order_without_inline_styles(headers, &block)
        [responses.map { |response| inline_style_response(response) }, order]
      end

    private
      def url_options
        Rails.application.config.action_mailer.default_url_options
      end

      def stylesheet_root
        Rails.root.join('public', 'stylesheets')
      end

      def inline_style_response(response)
        if response[:content_type] == 'text/html'
          response.merge :body => Roadie.inline_css(css_rules, response[:body], url_options)
        else
          response
        end
      end

      def css_targets
        return nil if @inline_style_css_targets == false
        Array(@inline_style_css_targets || self.class.default[:css] || []).map { |target| target.to_s }
      end

      def css_rules
        @css_rules ||= Roadie.load_css(stylesheet_root, css_targets) if css_targets.present?
      end
  end
end
