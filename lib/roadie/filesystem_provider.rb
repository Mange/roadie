require 'pathname'

module Roadie
  class FilesystemProvider < AssetProvider
    attr_reader :path

    def initialize(path = nil)
      super()
      if path
        @path = resolve_path(path)
      else
        @path = default_path
      end
    end

    def find(name)
      file = path.join(name)
      if file.exist?
        file.read.strip
      else
        return find("#{name}.css") if name.to_s !~ /\.css$/
        raise CSSFileNotFound.new(name, file.to_s)
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
