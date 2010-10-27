require 'uri'
require 'nokogiri'
require 'css_parser'

module MailStyle
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
        mail_without_inline_styles(headers.except(:css), &block)
      end

      def collect_responses_and_parts_order_with_inline_styles(headers, &block)
        responses, order = collect_responses_and_parts_order_without_inline_styles(headers, &block)
        new_responses = []
        responses.each do |response|
          new_responses << inline_style_response(response)
        end
        [new_responses, order]
      end

    private
      def inline_style_response(response)
        if response[:content_type] == 'text/html'
          response.merge :body => MailStyle.inline_css(css_rules, response[:body], Rails.application.config.action_mailer.default_url_options)
        else
          response
        end
      end

      def css_targets
        return nil if @inline_style_css_targets == false
        Array(@inline_style_css_targets || self.class.default[:css] || []).map { |target| target.to_s }
      end

      def css_rules
        @css_rules ||= MailStyle.load_css(Rails.root, css_targets) if css_targets.present?
      end
  end
end
