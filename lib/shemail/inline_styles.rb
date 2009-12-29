require 'nokogiri'
require 'css_parser'

module Shemail
  module InlineStyles
    module InstanceMethods
      def deliver_with_inline_styles!(mail = @mail)
        write_inline_styles(mail) if @css.present?
        deliver_without_inline_styles!(mail = @mail)
      end
      
      protected
      
      def write_inline_styles(mail)
        # Parse only text/html parts
        mail.parts.select{|p| p.content_type == 'text/html'}.each do |part|
          part.body = parse_html_part(part)
        end
      end
      
      def parse_html_part(part)
        # Parse original html
        html_document = Nokogiri::HTML.parse(part.body)
        
        # Write inline styles
        css_parser.each_selector do |selector, declaration, specificity|
          html_document.css(selector).each do |element|
            # Styles
            current_style = element['style'].to_s.split(';')
            new_style = declaration.to_s.split(';')
            
            # Concat styles
            style = (current_style + new_style).compact.uniq.map(&:strip)
            
            # Set new styles
            element['style'] = style.join(';')
          end
        end
        
        # Return new html as a string
        html_document.to_s
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
        css = @css.to_s.ends_with?('.css') ? @css.to_s : "#{@css}.css"
        path = File.join(RAILS_ROOT, 'public', 'stylesheets', css)
        File.exist?(path) ? path : raise(CSSFileNotFound)
      end
    end
    
    def self.included(receiver)
      receiver.send :include, InstanceMethods
      receiver.class_eval do
        adv_attr_accessor :css
        alias_method_chain :deliver!, :inline_styles
      end
    end
  end
end

ActionMailer::Base.send :include, Shemail::InlineStyles