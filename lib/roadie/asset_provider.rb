module Roadie
  class AssetProvider
    def load_css(files)
      files.map { |file| contents_of_file(file) }.join("\n")
    end

    def contents_of_file(name)
      raise "Not implemented"
    end
  end
end
