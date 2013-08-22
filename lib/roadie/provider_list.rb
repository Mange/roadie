module Roadie
  class ProviderList
    extend Forwardable
    include Enumerable
    include AssetProvider

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

    def_delegators :@providers, :each, :size, :push, :pop, :unshift, :shift
  end
end
