require 'pathname'

module Roadie
  # A provider that looks for files on the filesystem
  #
  # Usage:
  #   config.roadie.provider = FilesystemProvider.new("prefix", "path/to/stylesheets")
  #
  # Path specification follows certain rules thatare detailed in {#initialize}.
  #
  # @see #initialize
  class FilesystemProvider < AssetProvider
    # @return [Pathname] Pathname representing the directory of the assets
    attr_reader :path

    # Initializes a new instance of FilesystemProvider.
    #
    # The passed path can come in some variants:
    # * +Pathname+ - will be used as-is
    # * +String+ - If pointing to an absolute path, uses that path. If a relative path, relative from the +Rails.root+
    # * +nil+ - Use the default path (equal to "public/stylesheets")
    #
    # @example Pointing to a directory in the project
    #   FilesystemProvider.new(Rails.root.join("public", "assets"))
    #   FilesystemProvider.new("public/assets")
    #
    # @example Pointing to external resource
    #   FilesystemProvider.new("/home/app/stuff")
    #
    # @param [String] prefix The prefix (see {#prefix})
    # @param [String, Pathname, nil] path The path to use
    def initialize(prefix = "/stylesheets", path = nil)
      super(prefix)
      if path
        @path = resolve_path(path)
      else
        @path = default_path
      end
    end

    # Looks for the file in the tree. If the file cannot be found, and it does not end with ".css", the lookup
    # will be retried with ".css" appended to the filename.
    #
    # @return [String] contents of the file
    def find(name)
      base = remove_prefix(name)
      file = path.join(base)
      if file.exist?
        file.read.strip
      else
        return find("#{base}.css") if base.to_s !~ /\.css$/
        raise CSSFileNotFound.new(name, base.to_s)
      end
    end

    private
      def default_path
        resolve_path("public/stylesheets")
      end

      def resolve_path(path)
        if path.kind_of?(Pathname)
          @path = path
        else
          pathname = Pathname.new(path)
          if pathname.absolute?
            @path = pathname
          else
            @path = Roadie.app.root.join(path)
          end
        end
      end
  end
end
