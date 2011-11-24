module Roadie
  class AssetProvider
    def find_asset_from_url(url)
      raise "Not implemented"
    end

    def load_css(files)
      files.map { |file| contents_of_file(file) }.join("\n")
    end

    def contents_of_file(name)
      raise "Not implemented"
    end
  end
end
