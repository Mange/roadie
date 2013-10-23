require 'set'

module Roadie
  # Class that handles URL generation
  #
  # URL generation is all about converting relative URLs into absolute URLS
  # according to the given options.
  class UrlGenerator
    attr_reader :url_options

    # Create a new instance with the given URL options.
    #
    # Initializing without a host setting raises an error, as do unknown keys.
    #
    # @param [Hash] url_options
    # @option url_options [String] :host (required)
    # @option url_options [String, Integer] :port
    # @option url_options [String] :path root path
    # @option url_options [String] :scheme URL scheme ("http" is default)
    # @option url_options [String] :protocol alias for :scheme
    def initialize(url_options)
      raise ArgumentError, "No URL options were specified" unless url_options
      raise ArgumentError, "No :host was specified; options are: #{url_options.inspect}" unless url_options[:host]
      validate_options url_options

      @url_options = url_options
      @root_uri = build_root_uri
    end

    # Generate an absolute URL from a relative URL.
    #
    # If the passed path is already an absolute URL, it will be returned as-is.
    # If passed an blank path, the "root URL" will be returned. The root URL is
    # the URL that the {#url_options} would generate by themselves.
    #
    # An optional base can be specified for the URL generation. The base is
    # another relative path from the root that specifies an "offset" from which
    # the path was found in. A common usecase is to convert a relative path
    # found in a stylesheet which resides in a subdirectory. In that case
    # {base} could be "/stylesheets".
    #
    # @param [String] base The base which the relative path comes from
    # @returns [String] an absolute URL
    def generate_url(path, base = "/")
      return root_uri.to_s if path.nil? or path.empty?
      return path if path_is_absolute?(path)

      combine_segments(root_uri, base, path).to_s
    end

    private
    attr_reader :root_uri

    def build_root_uri
      path = make_absolute url_options[:path]
      port = parse_port url_options[:port]
      scheme = normalize_scheme(url_options[:scheme] || url_options[:protocol])
      URI::Generic.build(scheme: scheme, host: url_options[:host], port: port, path: path)
    end

    def combine_segments(root, base, path)
      new_path = apply_base(base, path)
      if root.path
        new_path = File.join(root.path, new_path)
      end
      root.merge(new_path)
    end

    def apply_base(base, path)
      if path[0] == "/"
        path
      else
        File.join(base, path)
      end
    end

    # Strip :// from any scheme, if present
    def normalize_scheme(scheme)
      return 'http' unless scheme
      scheme.to_s[/^\w+/]
    end

    def parse_port(port)
      (port ? port.to_i : port)
    end

    def make_absolute(path)
      if path.nil? || path[0] == "/"
        path
      else
        "/#{path}"
      end
    end

    def path_is_absolute?(path)
      not parse_path(path).relative?
    end

    def parse_path(path)
      URI.parse(path)
    rescue URI::InvalidURIError => error
      raise InvalidUrlPath.new(path, error)
    end

    VALID_OPTIONS = Set[:host, :port, :path, :protocol, :scheme].freeze

    def validate_options(options)
      keys = Set.new(options.keys)
      unless keys.subset? VALID_OPTIONS
        raise ArgumentError, "Passed invalid options: #{(keys - VALID_OPTIONS).to_a}, valid options are: #{VALID_OPTIONS.to_a}"
      end
    end
  end
end
