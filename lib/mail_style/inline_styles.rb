require 'uri'
require 'nokogiri'
require 'css_parser'

module MailStyle
  module InlineStyles
    DOCTYPE = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'

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
          response.merge(:body => transpose_styling(response[:body]))
        else
          response
        end
      end

      def transpose_styling(html)
        html_document = create_html_document(html)
        update_image_urls(html_document)

        element_styles = {}

        css_parser.each_selector do |selector, declaration, specificity|
          next if selector.include?(':') # Skip psuedo-classes
          html_document.css(selector).each do |element|
            declaration.to_s.split(';').each do |style|
              # Split style in attribute and value
              attribute, value = style.split(':').map(&:strip)

              # Set element style defaults
              element_styles[element] ||= {}
              element_styles[element][attribute] ||= { :specificity => 0, :value => '' }

              # Update attribute value if specificity is higher than previous values
              if element_styles[element][attribute][:specificity] <= specificity
                element_styles[element][attribute] = { :specificity => specificity, :value => value }
              end
            end
          end
        end

        element_styles.each_pair do |element, attributes|
          current_style = element['style'].to_s.split(';').sort
          new_style = attributes.map { |attribute, style| [attribute, update_css_urls(style[:value])].join(': ') }
          style = (current_style + new_style).compact.uniq.map(&:strip).sort
          element['style'] = style.join(';')
        end

        html_document.to_html
      end

      # Create Nokogiri html document from part contents and add/amend certain elements.
      # Reference: http://www.creativeglo.co.uk/email-design/html-email-design-and-coding-tips-part-2/
      def create_html_document(body)
        # Add doctype to html along with body
        document = Nokogiri::HTML.parse(DOCTYPE + body)

        # Set some meta stuff
        html = document.at_css('html')
        html['xmlns'] = 'http://www.w3.org/1999/xhtml'

        # Create <head> element if missing
        head = document.at_css('head')

        unless head.present?
          head = Nokogiri::XML::Node.new('head', document)
          document.at_css('body').add_previous_sibling(head)
        end

        # Add utf-8 content type meta tag
        meta = Nokogiri::XML::Node.new('meta', document)
        meta['http-equiv'] = 'Content-Type'
        meta['content'] = 'text/html; charset=utf-8'
        head.add_child(meta)

        # Grab all the styles that are inside <style> elements already in the document
        @inline_rules = ""
        document.css("style").each do |style|
          # Do not inline print media styles
          next if style['media'] == 'print'

          # <style data-immutable="true"> are kept in the document
          next if style['data-immutable'] == 'true'

          @inline_rules << style.content
          style.remove
        end

        # Return document
        document
      end

      def update_css_urls(style)
        if config.default_url_options and config.default_url_options[:host].present?
          # Replace urls in stylesheets
          style.gsub!(/url\((['"]?)(.*?)\1\)/i) { "url(#{$1}#{make_absolute_url($2, 'stylesheets')}#{$1})" }
        end
        style
      end

      def update_image_urls(document)
        document.css('img').each do |img|
          img['src'] = make_absolute_url(img['src'])
        end
      end

      def make_absolute_url(url, base_path = '')
        original_url = url

        unless original_url[URI::regexp(%w[http https])]
          protocol = config.default_url_options[:protocol]
          protocol = "http://" if protocol.blank?
          protocol+= "://" unless protocol.include?("://")

          host = config.default_url_options[:host]

          [host,protocol].each{|r| original_url.gsub!(r,"") }
          host = protocol+host unless host[URI::regexp(%w[http https])]

          url = URI.join host, base_path, original_url
        end

        url.to_s

      end

      def css_targets
        return [] if @inline_style_css_targets == false
        Array(@inline_style_css_targets || self.class.default[:css] || []).map { |target| target.to_s }
      end

      def css_parser
        CssParser::Parser.new.tap do |parser|
          parser.add_block!(css_rules) if css_targets.present?
          parser.add_block!(@inline_rules)
        end
      end

      def css_rules
        self.class.css_rules(css_targets)
      end
  end
end

ActionMailer::Base.send :include, MailStyle::InlineStyles