class TestProvider
  include Roadie::AssetProvider

  def initialize(files = {})
    @files = files
    @default = files[:default]
  end

  def find_stylesheet(name)
    @files.fetch(name, @default)
  end
end
