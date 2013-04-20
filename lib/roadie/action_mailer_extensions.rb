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
        if base.method_defined?(:collect_responses)
          alias_method_chain :collect_responses, :inline_styles
        else
          alias_method_chain :collect_responses_and_parts_order, :inline_styles
        end
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

        if headers.has_key?(:after_inlining)
          @after_inlining_handler = headers[:after_inlining]
        else
          @after_inlining_handler = default_after_inlining || Roadie.after_inlining_handler 
        end

        mail_without_inline_styles(headers, &block).tap do |email|
          email.header.fields.delete_if { |field| %w(css after_inlining).include?(field.name) }
        end
      end

      # Rails 4
      def collect_responses_with_inline_styles(headers, &block)
        responses = collect_responses_without_inline_styles(headers, &block)
        if Roadie.enabled?
          responses.map { |response| inline_style_response(response) }
        else
          responses
        end
      end

      # Rails 3
      def collect_responses_and_parts_order_with_inline_styles(headers, &block)
        responses, order = collect_responses_and_parts_order_without_inline_styles(headers, &block)
        if Roadie.enabled?
          [responses.map { |response| inline_style_response(response) }, order]
        else
          [responses, order]
        end
      end

    private
      def default_css_targets
        self.class.default[:css]
      end

      def default_after_inlining
        self.class.default[:after_inlining]
      end

      def after_inlining_handler 
        @after_inlining_handler 
      end

      def inline_style_response(response)
        if response[:content_type] == 'text/html'
          response.merge :body => Roadie.inline_css(Roadie.current_provider, css_targets, response[:body], url_options, after_inlining_handler)
        else
          response
        end
      end

      def css_targets
        Array.wrap(@targets || []).map { |target| resolve_target(target) }.compact.map(&:to_s)
      end

      def resolve_target(target)
        if target.kind_of? Proc
          instance_exec(&target)
        elsif target.respond_to? :call
          target.call
        else
          target
        end
      end
  end
end
