require 'uri'
require 'nokogiri'
require 'css_parser'

module MailStyle
  module InlineStyles
    DOCTYPE = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
    
    module InstanceMethods
      def create_mail_with_inline_styles
        write_inline_styles if @css.present?
        create_mail_without_inline_styles
      end
      
      protected
      
      def write_inline_styles
        # Parse only text/html parts
        @parts.select{|p| p.content_type == 'text/html'}.each do |part|
          part.body = parse_html_part(part)
        end
      end
      
      def parse_html_part(part)
        # Parse original html
        html_document = create_html_document(part.body)
        html_document = absolutize_image_sources(html_document)
        
        # Write inline styles
        css_parser.each_selector do |selector, declaration, specificity|
          html_document.css(selector).each do |element|
            # Styles
            current_style = element['style'].to_s.split(';').sort
            new_style = declaration.to_s.split(';').sort.map do |style|
              style = update_image_urls(style)
            end
            
            # Concat styles
            style = (current_style + new_style).compact.uniq.map(&:strip)
            
            # Set new styles
            element['style'] = style.join(';')
          end
        end
        
        # Strip all references to classes.
        html_document.css('*').remove_class
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
        
        # Return document
        document
      end
      
      # Update image urls
      def update_image_urls(style)
        if default_url_options[:host].present?
          # Replace urls in stylesheets
          style.gsub!($1, absolutize_url($1, 'stylesheets')) if style[/url\(['"]?(.*)['"]?\)/i]
        end
        
        style
      end
      
      # Absolutize URL (Absolutize? Seriously?)
      def absolutize_url(url, base_path = '')
        original_url = url
        
        unless original_url[URI::regexp(%w[http https])]
          # Calculate new path
          host = default_url_options[:host]
          url = URI.join("http://#{host}/", File.join(base_path, original_url)).to_s
        end
        
        url
      end

      # Css Parser
      def css_parser
        parser = CssParser::Parser.new
        parser.add_block!(css_rules)
        parser
      end
      
      # Css Rules
      def css_rules
        File.open(css_file).read
      end
      
      # Find the css file
      def css_file
        if @css.present?
          css = @css.to_s
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