# frozen_string_literal: true

module Roadie
  # Base class for all Roadie errors. Rescue this if you want to catch errors
  # from Roadie.
  #
  # If Roadie raises an error that does not inherit this class, please report
  # it as a bug.
  class Error < RuntimeError; end

  # Raised when Roadie encounters an invalid URL which cannot be parsed by
  # Ruby's +URI+ class.
  #
  # This could be a hint that something in your HTML or CSS is broken.
  class InvalidUrlPath < Error
    # The original error, raised from +URI+.
    attr_reader :cause

    def initialize(given_path, cause = nil)
      @cause = cause
      cause_message = if cause
        " Caused by: #{cause}"
      else
        ""
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

    # Extra message
    attr_reader :extra_message

    def initialize(css_name:, message: nil, provider: nil)
      @css_name = css_name
      @provider = provider
      @extra_message = message
      super build_message
    end

    protected

    def error_row
      "#{provider || "Unknown provider"}: #{extra_message}"
    end

    private

    def build_message
      message = +%(Could not find stylesheet "#{css_name}")
      message << ": #{extra_message}" if extra_message
      message << "\nUsed provider:\n#{provider}" if provider
      message
    end
  end

  class ProvidersFailed < CssNotFound
    attr_reader :errors

    def initialize(css_name:, providers:, errors:)
      @errors = errors
      super(
        css_name: css_name,
        message: "All providers failed",
        provider: providers
      )
    end

    private

    def build_message
      message = +%(Could not find stylesheet "#{css_name}": #{extra_message}\nUsed providers:\n)
      each_error_row(errors) do |row|
        message << "\t" << row << "\n"
      end
      message
    end

    def each_error_row(errors)
      errors.each do |error|
        case error
        when ProvidersFailed
          each_error_row(error.errors) { |row| yield row }
        when CssNotFound
          yield error.error_row
        else
          yield "Unknown provider (#{error.class}): #{error}"
        end
      end
    end
  end
end
