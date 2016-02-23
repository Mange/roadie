module Roadie
  # The main entry point for Roadie. A document represents a working unit and
  # is built with the input HTML and the configuration options you need.
  #
  # A Document must never be used from two threads at the same time. Reusing
  # Documents is discouraged.
  #
  # Stylesheets are added to the HTML from three different sources:
  # 1. Stylesheets inside the document ( +<style>+ elements)
  # 2. Stylesheets referenced by the DOM ( +<link>+ elements)
  # 3. The internal stylesheet (see {#add_css})
  #
  # The internal stylesheet is used last and gets the highest priority. The
  # rest is used in the same order as browsers are supposed to use them.
  #
  # @attr [#call] before_transformation Callback to call just before {#transform}ation begins. Will be called with the parsed DOM tree and the {Document} instance.
  # @attr [#call] after_transformation Callback to call just before {#transform}ation is completed. Will be called with the current DOM tree and the {Document} instance.
  class Document < DocumentBase

    # Transform the input HTML and return the processed HTML.
    #
    # @override
    #
    # Before the transformation begins, the {#before_transformation} callback
    # will be called with the parsed HTML tree and the {Document} instance, and
    # after all work is complete the {#after_transformation} callback will be
    # invoked in the same way.
    #
    # Most of the work is delegated to the superclass {DocumentBase}.
    #
    # @return [String] the transformed HTML
    def transform
      dom = Nokogiri::HTML.parse html

      callback before_transformation, dom

      improve dom
      inline dom
      rewrite_urls dom

      callback after_transformation, dom

      # #dup is called since it fixed a few segfaults in certain versions of Nokogiri
      dom.dup.to_html
    end
  end
end
