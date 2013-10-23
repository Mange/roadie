module Roadie
  class ProviderList
    extend Forwardable
    include Enumerable
    include AssetProvider

    def self.wrap(*providers)
      if providers.size == 1 && providers.first.class == self
        providers.first
      else
        new(providers.flatten)
      end
    end

    def initialize(providers)
      @providers = providers
    end

    def find_stylesheet(name)
      @providers.each do |provider|
        css = provider.find_stylesheet(name)
        return css if css
      end
      nil
    end

    # ProviderList can be coerced to an array. This makes Array#flatten work
    # with it, among other things.
    def to_ary() to_a end

    def_delegators :@providers, :each, :size, :push, :<<, :pop, :unshift, :shift
  end
end
