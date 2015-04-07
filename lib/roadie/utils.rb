module Roadie
  module Utils
    def path_is_absolute?(path)
      # Ruby's URI is pretty unforgiving, but roadie aims to be. Don't involve
      # URI for URLs that's easy to determine to be absolute.
      # URLs starting with a scheme (http:, data:) are absolute.
      #
      # URLs that start with double slashes (//css/app.css) are also absolute
      # in modern browsers, but most email clients do not understand them.
      return true if path =~ %r{^(\w+:|//)}

      begin
        !URI.parse(path).relative?
      rescue URI::InvalidURIError => error
        raise InvalidUrlPath.new(path, error)
      end
    end
    module_function :path_is_absolute?
  end
end
