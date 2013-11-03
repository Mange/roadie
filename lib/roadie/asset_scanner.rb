module Roadie
  # @api private
  #
  # The asset scanner's main usage is finding and/or extracting styles from a
  # DOM tree. Referenced styles will be found using the provided asset
  # provider.
  #
  # Any style declaration tagged with +data-roadie-ignore+ will be ignored.
  class AssetScanner
    attr_reader :dom, :asset_provider

    # @param [Nokogiri::HTML::Document] dom
    # @param [#find_stylesheet!] asset_provider
    def initialize(dom, asset_provider)
      @dom = dom
      @asset_provider = asset_provider
    end

    # Looks for all non-ignored stylesheets and returns them.
    #
    # This method will *not* mutate the DOM and is safe to call multiple times.
    #
    # The order of the array corresponds with the document order in the DOM.
    #
    # @see #extract_css
    # @return [Enumerable<Stylesheet>] every found stylesheet
    def find_css
      @dom.css(STYLE_ELEMENT_QUERY).map { |element| read_stylesheet(element) }.compact
    end

    # Looks for all non-ignored stylesheets, removes their references from the
    # DOM and then returns them.
    #
    # This will mutate the DOM tree.
    #
    # The order of the array corresponds with the document order in the DOM.
    #
    # @see #find_css
    # @return [Enumerable<Stylesheet>] every extracted stylesheet
    def extract_css
      @dom.css(STYLE_ELEMENT_QUERY).map { |element|
        stylesheet = read_stylesheet(element)
        element.remove if stylesheet
        stylesheet
      }.compact
    end

    private

    STYLE_ELEMENT_QUERY = (
      "style:not([data-roadie-ignore]), " +
      # TODO: When using Nokogiri 1.6.1 and later; we may use a double :not here
      #       instead of the extra code inside #read_stylesheet, and the #compact
      #       call in #find_css.
      "link[rel=stylesheet][href]:not([data-roadie-ignore])"
    ).freeze

    # Cleans out stupid CDATA and/or HTML comments from the style text
    # TinyMCE causes this, allegedly
    CLEANING_MATCHER = /
      (^\s*             # Beginning-of-lines matches
        (<!\[CDATA\[)|
        (<!--+)
      )|(               # End-of-line matches
        (--+>)|
        (\]\]>)
      $)
    /x.freeze

    def read_stylesheet(element)
      if element.name == "style"
        read_style_element element
      else
        read_link_element element
      end
    end

    def read_style_element(element)
      Stylesheet.new "(inline)", clean_css(element.text.strip)
    end

    def read_link_element(element)
      if element['media'] != "print" && element["href"]
        asset_provider.find_stylesheet! element['href']
      end
    end

    def clean_css(css)
      css.gsub(CLEANING_MATCHER, '')
    end
  end
end
