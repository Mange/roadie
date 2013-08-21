class TestProvider < Roadie::AssetProvider
  def initialize(prefix_or_files = {}, files = nil)
    if prefix_or_files.is_a?(Hash)
      super()
      @files = prefix_or_files
    else
      super(prefix_or_files)
      @files = files
    end
    @default = @files[:default]
  end

  def find(name)
    @files.fetch(remove_prefix name) {
      @default or raise Roadie::CSSFileNotFound, name
    }
  end
end
