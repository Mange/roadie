module Roadie
  class PathRewriterProvider
    def initialize(provider, &block)
      @provider = provider
      @block = block
    end

    def find_stylesheet(path)
      @provider.find_stylesheet(@block.call(path))
    end

    def find_stylesheet!(path)
      @provider.find_stylesheet!(@block.call(path))
    end
  end
end
