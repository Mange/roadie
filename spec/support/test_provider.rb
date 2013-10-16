class TestProvider
  include Roadie::AssetProvider

  def initialize(files = {})
    @files = files
    @default = files[:default]
  end

  def find_stylesheet(name)
    contents = @files.fetch(name, @default)
    Roadie::Stylesheet.new name, contents if contents
  end
end
