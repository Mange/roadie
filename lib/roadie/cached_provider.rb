module Roadie
  class CachedProvider
    attr_reader :cache

    def initialize(upstream, cache = {})
      @upstream = upstream
      @cache = cache
    end

    def find_stylesheet(name)
      cache_fetch(name) do
        @upstream.find_stylesheet(name)
      end
    end

    def find_stylesheet!(name)
      cache_fetch(name) do
        @upstream.find_stylesheet!(name)
      end
    end

    private
    def cache_fetch(name)
      cache[name] || cache[name] = yield
    rescue CssNotFound
      cache[name] = nil
      raise
    end
  end
end
