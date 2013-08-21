module Roadie
  class ProviderList
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
  end
end
