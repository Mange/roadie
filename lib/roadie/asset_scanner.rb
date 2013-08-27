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

    def read_css(element)
      if element.name == "style"
        element.text.strip
      else
        unless element['media'] == "print"
          asset_provider.find_stylesheet(element['href'])
        end
      end
    end
  end
end
