module Roadie
  # Include this module to get some standard behavior for your own asset providers.
  module AssetProvider
    def find_stylesheet!(name)
      find_stylesheet(name) or raise CssNotFound, name
    end
  end
end
