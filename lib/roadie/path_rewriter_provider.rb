module Roadie
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
