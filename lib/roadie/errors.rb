module Roadie
  # Base class for all Roadie errors. Rescue this if you want to catch errors
  # from Roadie.
  #
  # If Roadie raises an error that does not inherit this class, please report
  # it as a bug.
  class Error < RuntimeError; end

  # Raised when a declaration which cannot be parsed is encountered.
  #
  # A declaration is something like "font-size: 12pt;".
  class UnparseableDeclaration < Error; end

  # Raised when Roadie encounters an invalid URL which cannot be parsed by
  # Ruby's +URI+ class.
  #
  # This could be a hint that something in your HTML or CSS is broken.
  class InvalidUrlPath < Error
    # The original error, raised from +URI+.
    attr_reader :cause

    def initialize(given_path, cause = nil)
      @cause = cause
      if cause
        cause_message = " Caused by: #{cause}"
      else
        cause_message = ""
      end
      super "Cannot use path \"#{given_path}\" in URL generation.#{cause_message}"
    end
  end

  # Raised when an asset provider cannot find a stylesheet.
  #
  # If you are writing your own asset provider, make sure to raise this in the
  # +#find_stylesheet!+ method.
  #
  # @see AssetProvider
  class CssNotFound < Error
    # The name of the stylesheet that cannot be found
    attr_reader :css_name

    # Provider used when finding
    attr_reader :provider

    # TODO: Change signature in the next major version of Roadie.
    def initialize(css_name, extra_message = nil, provider = nil)
      @css_name = css_name
      @provider = provider
      super build_message(extra_message)
    end

    private
    def build_message(extra_message)
      message = %(Could not find stylesheet "#{css_name}")
      message << ": #{extra_message}" if extra_message
      message << "\nUsed provider:\n#{provider}" if provider
      message
    end
  end
end
