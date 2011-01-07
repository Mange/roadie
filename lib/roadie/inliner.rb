module Roadie
  # This class is the core of Roadie as it does all the actual work. You just give it
  # the CSS rules, the HTML and the url_options for rewriting URLs and let it go on
  # doing all the heavy lifting and building.
  class Inliner
    # Regexp matching all the url() declarations in CSS
    #
    # It matches without any quotes and with both single and double quotes
    # inside the parenthesis. There's much room for improvement, of course.
    CSS_URL_REGEXP = %r{
      url\(
        (["']?)
        (
          [^(]*            # Text leading up to before opening parens
          (?:\([^)]*\))*   # Texts containing parens pairs
          [^(]+            # Texts without parens - required
        )
        \1                 # Closing quote
      \)
    }x

    # Initialize a new Inliner with the given CSS, HTML and url_options.
    #
    # @param [String] css
    # @param [String] html
    # @param [Hash] url_options Supported keys: +:host+, +:port+ and +:protocol+
    def initialize(css, html, url_options)
      @css = css
      @inline_css = []
      @html = html
      @url_options = url_options
    end

    # Start the inlining and return the final HTML output
    # @return [String]
    def execute
      adjust_html do |document|
        add_missing_structure(document)
        extract_inline_style_elements(document)
        inline_css_rules(document)
        make_image_urls_absolute(document)
        make_style_urls_absolute(document)
      end
    end

    private
      attr_reader :css, :html, :url_options

      def inline_css
        @inline_css.join("\n")
      end

      def parsed_css
        CssParser::Parser.new.tap do |parser|
          parser.add_block!(css) if css
          parser.add_block!(inline_css)
        end
      end

      def adjust_html
        Nokogiri::HTML.parse(html).tap do |document|
          yield document
        end.to_html
      end

      def add_missing_structure(document)
        html_node = document.at_css('html')
        html_node['xmlns'] ||= 'http://www.w3.org/1999/xhtml'

        if document.at_css('html > head').present?
          head = document.at_css('html > head')
        else
          head = Nokogiri::XML::Node.new('head', document)
          document.at_css('html').children.before(head)
        end

        unless document.at_css('html > head > meta[http-equiv=Content-Type]')
          meta = Nokogiri::XML::Node.new('meta', document)
          meta['http-equiv'] = 'Content-Type'
          meta['content'] = 'text/html; charset=utf-8'
          head.add_child(meta)
        end
      end

      def extract_inline_style_elements(document)
        document.css("style").each do |style|
          next if style['media'] == 'print' or style['data-immutable']
          @inline_css << style.content
          style.remove
        end
      end

      def inline_css_rules(document)
        matched_elements = {}
        assign_rules_to_elements(document, matched_elements)

        matched_elements.each do |element, rules|
          rules_string = rules.map { |property, rule| [property, rule[:value]].join(':')  }.join('; ')
          element['style'] = [rules_string, element['style']].compact.join('; ')
        end
      end

      def assign_rules_to_elements(document, matched_elements)
        parsed_css.each_rule_set do |rules|
          rules.selectors.reject { |selector| selector.include?(':') }.each do |selector|
            document.css(selector.strip).each do |element|
              register_rules_for_element(matched_elements, element, selector, rules)
            end
          end
        end
      end

      def register_rules_for_element(store, element, selector, rules)
        specificity = CssParser.calculate_specificity(selector)
        element_rules = (store[element] ||= {})
        rules.each_declaration do |property, value, important|
          stored = (element_rules[property] ||= {:specificity => -1})
          more_specific = (stored[:specificity] <= specificity)
          if (important and not stored[:important]) or (important and stored[:important] and more_specific) or (more_specific and not stored[:important])
            stored.merge!(:value => value, :specificity => specificity, :important => important)
          end
        end
      end

      def make_image_urls_absolute(document)
        document.css('img').each do |img|
          img['src'] = ensure_absolute_url(img['src']) if img['src']
        end
      end

      def make_style_urls_absolute(document)
        document.css('*[style]').each do |element|
          styling = element['style']
          element['style'] = styling.gsub(CSS_URL_REGEXP) { "url(#{$1}#{ensure_absolute_url($2, '/stylesheets')}#{$1})" }
        end
      end

      def ensure_absolute_url(url, base_path = nil)
        base, uri = absolute_url_base(base_path), URI.parse(url)
        if uri.relative? and base
          base.merge(uri).to_s
        else
          uri.to_s
        end
      rescue URI::InvalidURIError
        return url
      end

      def absolute_url_base(base_path)
        return nil unless url_options
        URI::Generic.build({
          :scheme => url_options[:protocol] || 'http',
          :host => url_options[:host],
          :port => url_options[:port],
          :path => base_path
        })
      end
  end
end
