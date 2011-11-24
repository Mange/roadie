module Roadie
  # @abstract Subclass to create your own providers
  class AssetProvider
    # Iterates all the passed elements and calls {#find} on them, joining the results with a newline.
    #
    # @example
    #   MyProvider.all("first", "second.css", :third)
    #
    # @param [Array] files The target files to be loaded together
    # @raise [CSSFileNotFound] In case any of the elements is not found
    # @see #find
    def all(files)
      files.map { |file| find(file) }.join("\n")
    end

    # @abstract Implement in your own subclass
    #
    # Return the CSS contents of the file specified. A provider should not care about
    # the +.css+ extension; it can, however, behave differently if it's passed or not.
    #
    # If the asset cannot be found, the method should raise {CSSFileNotFound}.
    #
    # @example
    #   MyProvider.find("mystyle")
    #   MyProvider.find("mystyle.css")
    #   MyProvider.find(:mystyle)
    #
    # @param [String, Symbol] name Name of the file requested
    # @raise [CSSFileNotFound] In case any of the elements is not found
    def find(name)
      raise "Not implemented"
    end
  end
end
