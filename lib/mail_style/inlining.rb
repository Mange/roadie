module MailStyle
  class Inlining
    DOCTYPE = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'

    attr_reader :css, :html, :url_options
    def initialize(css, html, url_options)
      @css = css
      @html = html
      @url_options = url_options
    end

    def execute
      html_document = create_html_document(html)
      update_image_urls(html_document)

      element_styles = {}

      css_parser(css).each_selector do |selector, declaration, specificity|
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

    private
      def css_parser(css)
        CssParser::Parser.new.tap do |parser|
          parser.add_block!(css) if css
          parser.add_block!(@inline_rules)
        end
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
        if url_options and url_options[:host].present?
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
          protocol = url_options[:protocol]
          protocol = "http://" if protocol.blank?
          protocol+= "://" unless protocol.include?("://")

          host = url_options[:host]

          [host,protocol].each{|r| original_url.gsub!(r,"") }
          host = protocol+host unless host[URI::regexp(%w[http https])]

          url = URI.join host, base_path, original_url
        end

        url.to_s

      end
  end
end