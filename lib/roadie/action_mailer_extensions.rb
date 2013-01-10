require 'uri'
require 'nokogiri'
require 'css_parser'
require 'active_support/core_ext/proc'

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

        mail_without_inline_styles(headers, &block).tap do |email|
          email.header.fields.delete_if { |field| field.name == 'css' }
        end
      end

      if ActionMailer::Base.method_defined?(:collect_responses) # Rails 4

        def collect_responses_with_inline_styles(headers, &block)
          responses = collect_responses_without_inline_styles(headers, &block)
          if Roadie.enabled?
            responses.map { |response| inline_style_response(response) }
          else
            responses
          end
        end

      else # Rails 3

        def collect_responses_and_parts_order_with_inline_styles(headers, &block)
          responses, order = collect_responses_and_parts_order_without_inline_styles(headers, &block)
          if Roadie.enabled?
            [responses.map { |response| inline_style_response(response) }, order]
          else
            [responses, order]
          end
        end

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
        Array.wrap(@targets || []).map { |target| resolve_target(target) }.compact.map(&:to_s)
      end

      def resolve_target(target)
        if target.kind_of? Proc
          # Use Ruby 1.9 #instance_exec when possible
          if respond_to?(:instance_exec)
            instance_exec(&target)
          else
            # Use Rails' Proc#bind. Deprecated in Rails 4.
            target.bind(self).call
          end
        elsif target.respond_to? :call
          target.call
        else
          target
        end
      end
  end
end
