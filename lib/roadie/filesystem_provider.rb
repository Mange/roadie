module Roadie
  class FilesystemProvider
    InsecurePathError = Class.new(RuntimeError)

    include AssetProvider
    attr_reader :path

    def initialize(path = Dir.pwd)
      @path = path
    end

    def find_stylesheet(name)
      file_path = build_file_path(name)
      File.read(file_path) if File.exist? file_path
    end

    private
    def build_file_path(name)
      raise InsecurePathError, name if name.include?("..")
      File.join(@path, name)
    end
  end
end
