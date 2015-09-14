module Roadie
  # @api public
  # This provider acts a bit like a pipeline in normal UNIX parlour by enabling
  # you to make changes to the requested path. Some uses of this include:
  #
  #   * Convert absolute URLs into local filesystem paths.
  #   * Convert between external DNS name into internal naming.
  #   * Changing path structure of filenames.
  #   * Removing digests from filenames.
  #   * Handle query string logic.
  #   * Skipping known-bad paths.
  #
  # There might be other useful things you could use it for. The basic premise
  # is that a path is sent in to this provider, maybe modified and then passed
  # on to the "upstream" provider (or {ProviderList}).
  #
  # If the block returns {nil} or {false}, the upstream provider will not be
  # invoked and it will be treated as "not found". This makes it possible to
  # use this provider as a filter only.
  #
  # @example Simple regex
  #   provider = Roadie::PathRewriterProvider.new(other_provider) { |path|
  #     path.gsub(/-[a-f0-9]+\.css$/, '.css')
  #   }
  #
  # @example Filtering assets
  #   # Only assets containing "email" in the path will be considered by other_provider
  #   only_email_provider = Roadie::PathRewriterProvider.new(other_provider) { |path|
  #     path =~ /email/ ? path : nil
  #   }
  #
  # @example Handling "external" app assets as local assets
  #   document.external_asset_providers = [
  #     # Look for assets from "myapp.com" just like if we just specified a local path
  #     Roadie::PathRewriterProvider.new(document.asset_providers) { |url|
  #       uri = URI.parse(url)
  #       uri.path if uri.host == "myapp.com"
  #     },
  #     # Any other asset should be downloaded like normal
  #     Roadie::NetHttpProvider.new
  #   ]
  class PathRewriterProvider
    attr_reader :provider, :filter

    def initialize(provider, &filter)
      @provider = provider
      @filter = filter
    end

    def find_stylesheet(path)
      new_path = filter.call(path)
      provider.find_stylesheet(new_path) if new_path
    end

    def find_stylesheet!(path)
      new_path = filter.call(path)
      if new_path
        provider.find_stylesheet!(new_path)
      else
        raise CssNotFound, "Filter returned #{new_path.inspect}"
      end
    end
  end
end
