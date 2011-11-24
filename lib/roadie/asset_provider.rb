module Roadie
  class AssetProvider
    def all(files)
      files.map { |file| find(file) }.join("\n")
    end

    def find(name)
      raise "Not implemented"
    end
  end
end
