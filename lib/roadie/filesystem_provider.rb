module Roadie
  class FilesystemProvider
    InsecurePathError = Class.new(Error)

    include AssetProvider
    attr_reader :path

    def initialize(path = Dir.pwd)
      @path = path
    end

    def find_stylesheet(name)
      file_path = build_file_path(name)
      if File.exist? file_path
        Stylesheet.new file_path, File.read(file_path)
      end
    end

    private
    def build_file_path(name)
      raise InsecurePathError, name if name.include?("..")
      File.join(@path, name)
    end
  end
end
