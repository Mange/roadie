require 'uri'
require 'nokogiri'
require 'css_parser'

module MailStyle
  module InlineStyles
    DOCTYPE = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'

    module InstanceMethods
      def create_mail_with_inline_styles
        write_inline_styles
        create_mail_without_inline_styles
      end

      protected

      # Flatten nested parts
      def collect_parts(parts)
        nested = parts.present? ? parts.map { |p| collect_parts(p.parts) }.flatten : []
        [parts, nested].flatten
      end

      def write_inline_styles
        parts = collect_parts(@parts)

        # Parse only text/html parts
        parsable_parts(@parts).each do |part|
          part.body = parse_html(part.body)
        end

        # Parse single part emails if the body is html
        real_content_type, ctype_attrs = parse_content_type
        self.body = parse_html(body) if body.is_a?(String) && real_content_type == 'text/html'
      end
      
      def parsable_parts(parts)
        selected = []
        parts.each do |part|
          selected << part if part.content_type == 'text/html'
          selected += parsable_parts(part.parts)
        end
        selected
      end

      def parse_html(html)
        # Parse original html
        html_document = create_html_document(html)
        html_document = absolutize_image_sources(html_document)

        # Write inline styles
        element_styles = {}

        css_parser.each_selector do |selector, declaration, specificity|
          next if selector.include?(':')
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

        # Loop through element styles
        element_styles.each_pair do |element, attributes|
          # Elements current styles
          current_style = element['style'].to_s.split(';').sort

          # Elements new styles
          new_style = attributes.map{|attribute, style| "#{attribute}: #{update_image_urls(style[:value])}"}

          # Concat styles
          style = (current_style + new_style).compact.uniq.map(&:strip).sort

          # Set new styles
          element['style'] = style.join(';')
        end

        # Return HTML
        html_document.to_html
      end

      def absolutize_image_sources(document)
        document.css('img').each do |img|
          src = img['src']
          img['src'] = src.gsub(src, absolutize_url(src))
        end

        document
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

      # Update image urls
      def update_image_urls(style)
        if default_url_options[:host].present?
          # Replace urls in stylesheets
          style.gsub!($1, absolutize_url($1, 'stylesheets')) if style[/url\(['"]?(.*?)['"]?\)/i]
        end

        style
      end

       # Absolutize URL (Absolutize? Seriously?)
      def absolutize_url(url, base_path = '')
        original_url = url

        unless original_url[URI::regexp(%w[http https])]
          protocol = default_url_options[:protocol]
          protocol = "http://" if protocol.blank?
          protocol+= "://" unless protocol.include?("://")

          host = default_url_options[:host]

          [host,protocol].each{|r| original_url.gsub!(r,"") }
          host = protocol+host unless host[URI::regexp(%w[http https])]

          url = URI.join host, base_path, original_url
        end

        url.to_s

      end

      # Css Parser
      def css_parser
        parser = CssParser::Parser.new

        parser.add_block!(css_rules) if @css.present?
        parser.add_block!(@inline_rules)
        parser
      end

      # Css Rules
      def css_rules
        if @css.is_a?(Array)
          @css.collect{|r| File.read(css_file(r)) }.join("\n")
        else
          File.read css_file(@css)
        end
      end

      # Find the css file
      def css_file(name=nil)
        if name.present?
          css = name.to_s
          css = css[/\.css$/] ? css : "#{css}.css"
          path = File.join(RAILS_ROOT, 'public', 'stylesheets', css)
          File.exist?(path) ? path : raise(CSSFileNotFound)
        end
      end
    end

    def self.included(receiver)
      receiver.send :include, InstanceMethods
      receiver.class_eval do
        adv_attr_accessor :css
        alias_method_chain :create_mail, :inline_styles
      end
    end
  end
end

ActionMailer::Base.send :include, MailStyle::InlineStyles