module Roadie
  # @api public
  # The {CachedProvider} wraps another provider (or {ProviderList}) and caches
  # the response from it.
  #
  # The default cache store is a instance-specific hash that lives for the
  # entire duration of the instance. If you want to share hash between
  # instances, pass your own hash-like object. Just remember to not allow this
  # cache to grow without bounds, which a shared hash would do.
  #
  # Not found assets are not cached currently, but it's possible to extend this
  # class in the future if there is a need for it. Remember this if you have
  # providers with very slow failures.
  #
  # The cache store must accept {Roadie::Stylesheet} instances, and return such
  # instances when fetched. It must respond to `#[name]` and `#[name]=` to
  # retrieve and set entries, respectively. The `#[name]=` method also needs to
  # return the instance again.
  #
  # @example Global cache
  #   Application.asset_cache = Hash.new
  #   slow_provider = MyDatabaseProvider.new(Application)
  #   provider = Roadie::CachedProvider.new(slow_provider, Application.asset_cache)
  #
  # @example Custom cache store
  #   class MyRoadieMemcacheStore
  #     def initialize(memcache)
  #       @memcache = memcache
  #     end
  #
  #     def [](path)
  #       css = memcache.read("assets/#{path}/css")
  #       if css
  #         name = memcache.read("assets/#{path}/name") || "cached #{path}"
  #         Roadie::Stylesheet.new(name, css)
  #       end
  #     end
  #
  #     def []=(path, stylesheet)
  #       memcache.write("assets/#{path}/css", stylesheet.to_s)
  #       memcache.write("assets/#{path}/name", stylesheet.name)
  #       stylesheet # You need to return the set Stylesheet
  #     end
  #   end
  #
  class CachedProvider
    # The cache store used by this instance.
    attr_reader :cache

    # @param upstream [an asset provider] The wrapped asset provider
    # @param cache [#[], #[]=] The cache store to use.
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
