# frozen_string_literal: true

module Roadie
  # This module can be included in your own code to help you implement the
  # standard behavior for asset providers.
  #
  # It helps you by declaring {#find_stylesheet!} in the terms of #find_stylesheet in your own class.
  module AssetProvider
    def find_stylesheet!(name)
      find_stylesheet(name) or raise(
        CssNotFound.new(css_name: name, provider: self)
      )
    end
  end
end
