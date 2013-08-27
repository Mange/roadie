module Roadie
  # Class that rewrites URLs in source material
  class UrlRewriter
    # @param [UrlGenerator] generator
    def initialize(generator)
      @generator = generator
    end

    # Mutates the passed DOM tree, rewriting certain element's attributes.
    #
    # This will make all a[href] and img[src] into absolute URLs.
    #
    # @param [Nokogiri::HTML::Document] dom
    # @return [nil] DOM tree is mutated
    def transform_dom(dom)
      # Use only a single loop to do this
      dom.css("a[href], img[src]").each do |element|
        case element.name
        when "a"
          element["href"] = generate_url element["href"]
        when "img"
          element["src"] = generate_url element["src"]
        end
      end
      nil
    end

    private
    def generate_url(*args) @generator.generate_url(*args) end
  end
end
