module Roadie
  # Include this module to get some standard behavior for your own asset providers.
  module AssetProvider
    def find_stylesheet!(name)
      find_stylesheet(name) or raise CSSFileNotFound, name
    end
  end
end
