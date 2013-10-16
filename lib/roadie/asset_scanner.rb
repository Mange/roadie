module Roadie
  class AssetScanner
    attr_reader :dom, :asset_provider

    def initialize(dom, asset_provider)
      @dom = dom
      @asset_provider = asset_provider
    end

    def find_css
      @dom.css(STYLE_ELEMENT_QUERY).map { |element| read_css(element) }.compact
    end

    def extract_css
      @dom.css(STYLE_ELEMENT_QUERY).map { |element|
        css = read_css(element)
        element.remove if css
        css
      }.compact
    end

    private

    STYLE_ELEMENT_QUERY = (
      "style:not([data-roadie-ignore]), " +
      # TODO: When using Nokogiri 1.6.1 and later; we may use a double :not here
      #       instead of the extra code inside #read_css, and the #compact
      #       call in #find_css.
      "link[rel=stylesheet][href]:not([data-roadie-ignore])"
    ).freeze

    CLEANING_MATCHER = /
      (^\s*             # Beginning-of-lines matches
        (<!\[CDATA\[)|
        (<!--+)
      )|(               # End-of-line matches
        (--+>)|
        (\]\]>)
      $)
    /x.freeze

    def read_css(element)
      if element.name == "style"
        read_style_element element
      else
        read_link_element element
      end
    end

    def read_style_element(element)
      clean_css element.text.strip
    end

    def read_link_element(element)
      if element['media'] != "print" && element["href"]
        stylesheet = asset_provider.find_stylesheet element['href']
        stylesheet.to_s if stylesheet # TODO: AssetScanner should return Stylesheets too
      end
    end

    def clean_css(css)
      css.gsub(CLEANING_MATCHER, '')
    end
  end
end
