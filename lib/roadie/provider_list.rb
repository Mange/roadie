module Roadie
  class ProviderList < AssetProvider
    def initialize(providers)
      super()
      @providers = providers
    end

    def find(name)
      @providers.each do |provider|
        css = safe_find(provider, name)
        return css if css
      end
      raise CSSFileNotFound, name
    end

    private

    def safe_find(provider, name)
      provider.find(name)
    rescue CSSFileNotFound
      nil
    end
  end
end
