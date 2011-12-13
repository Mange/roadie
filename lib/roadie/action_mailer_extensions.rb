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
        if headers.has_key?(:css)
          @targets = headers[:css]
        else
          @targets = default_css_targets
        end

        mail_without_inline_styles(headers, &block).tap do |email|
          email.header.fields.delete_if { |field| field.name == 'css' }
        end
      end

      def collect_responses_and_parts_order_with_inline_styles(headers, &block)
        responses, order = collect_responses_and_parts_order_without_inline_styles(headers, &block)
        [responses.map { |response| inline_style_response(response) }, order]
      end

    private
      def default_css_targets
        self.class.default[:css]
      end

      def inline_style_response(response)
        if response[:content_type] == 'text/html'
          response.merge :body => Roadie.inline_css(Roadie.current_provider, css_targets, response[:body], url_options)
        else
          response
        end
      end

      def css_targets
        return [] unless @targets
        Array.wrap(@targets || []).map { |target| target.to_s }
      end
  end
end
