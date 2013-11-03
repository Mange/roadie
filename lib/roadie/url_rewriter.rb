module Roadie
  # @api private
  #
  # Class that rewrites URLs in the DOM.
  class UrlRewriter
    # @param [UrlGenerator] generator
    def initialize(generator)
      @generator = generator
    end

    # Mutates the passed DOM tree, rewriting certain element's attributes.
    #
    # This will make all a[href] and img[src] into absolute URLs, as well as
    # all "url()" directives inside style-attributes.
    #
    # [nil] is returned so no one can misunderstand that this method mutates
    # the passed instance.
    #
    # @param [Nokogiri::HTML::Document] dom
    # @return [nil] DOM tree is mutated
    def transform_dom(dom)
      # Use only a single loop to do this
      dom.css("a[href], img[src], *[style]").each do |element|
        transform_element_style element if element.has_attribute?('style')
        transform_element element
      end
      nil
    end

    # Mutates passed CSS, rewriting url() directives.
    #
    # This will make all URLs inside url() absolute.
    #
    # [nil] is returned so no one can misunderstand that this method mutates
    # the passed string.
    #
    # @param [String] css the css to mutate
    # @return [nil] css is mutated
    def transform_css(css)
      css.gsub!(CSS_URL_REGEXP) do
        matches = Regexp.last_match
        "url(#{matches[:quote]}#{generate_url(matches[:url])}#{matches[:quote]})"
      end
    end

    private
    def generate_url(*args) @generator.generate_url(*args) end

    # Regexp matching all the url() declarations in CSS
    #
    # It matches without any quotes and with both single and double quotes
    # inside the parenthesis. There's much room for improvement, of course.
    CSS_URL_REGEXP = %r{
      url\(
        (?<quote>
          (?:["']|%22)?    # Optional opening quote
        )
        (?<url>            # The URL.
                           # We match URLs with parenthesis inside it here,
                           # so url(foo(bar)baz) will match correctly.
          [^(]*               # Text leading up to before opening parens
          (?:\([^)]*\))*      # Texts containing parens pairs
          [^(]+               # Texts without parens - required
        )
        \k'quote'          # Closing quote
      \)
    }x

    def transform_element(element)
      case element.name
      when "a" then element["href"] = generate_url element["href"]
      when "img" then element["src"] = generate_url element["src"]
      end
    end

    def transform_element_style(element)
      # We need to use a setter for Nokogiri to detect the string mutation.
      # If nokogiri used "dumber" data structures, this would all be redundant.
      css = element["style"]
      transform_css css
      element["style"] = css
    end
  end
end
