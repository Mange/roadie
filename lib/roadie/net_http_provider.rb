# frozen_string_literal: true

require "set"
require "uri"
require "net/http"

module Roadie
  # @api public
  # External asset provider that downloads stylesheets from some other server
  # using Ruby's built-in {Net::HTTP} library.
  #
  # You can pass a whitelist of hosts that downloads are allowed on.
  #
  # @example Allowing all downloads
  #   provider = Roadie::NetHttpProvider.new
  #
  # @example Only allowing your own app domains
  #   provider = Roadie::NetHttpProvider.new(
  #     whitelist: ["myapp.com", "assets.myapp.com", "www.myapp.com"]
  #   )
  class NetHttpProvider
    attr_reader :whitelist

    # @option options [Array<String>] :whitelist ([]) A list of host names that downloads are allowed from. Empty set means everything is allowed.
    def initialize(options = {})
      @whitelist = host_set(Array(options.fetch(:whitelist, [])))
    end

    def find_stylesheet(url)
      find_stylesheet!(url)
    rescue CssNotFound
      nil
    end

    def find_stylesheet!(url)
      response = download(url)
      if response.is_a? Net::HTTPSuccess
        Stylesheet.new(url, response_body(response))
      else
        raise CssNotFound.new(
          css_name: url,
          message: "Server returned #{response.code}: #{truncate response.body}",
          provider: self
        )
      end
    rescue Timeout::Error
      raise CssNotFound.new(css_name: url, message: "Timeout", provider: self)
    end

    def to_s
      inspect
    end

    def inspect
      "#<#{self.class} whitelist: #{whitelist.inspect}>"
    end

    private

    def host_set(hosts)
      hosts.each { |host| validate_host(host) }.to_set
    end

    def validate_host(host)
      if host.nil? || host.empty? || host == "." || host.include?("/")
        raise ArgumentError, "#{host.inspect} is not a valid hostname"
      end
    end

    def download(url)
      url = "https:#{url}" if url.start_with?("//")
      uri = URI.parse(url)
      if access_granted_to?(uri.host)
        get_response(uri)
      else
        raise CssNotFound.new(
          css_name: url,
          message: "#{uri.host} is not part of whitelist!",
          provider: self
        )
      end
    end

    def get_response(uri)
      if RUBY_VERSION >= "2.0.0"
        Net::HTTP.get_response(uri)
      else
        Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == "https")) do |http|
          http.request(Net::HTTP::Get.new(uri.request_uri))
        end
      end
    end

    def access_granted_to?(host)
      whitelist.empty? || whitelist.include?(host)
    end

    def truncate(string)
      if string.length > 50
        string[0, 49] + "…"
      else
        string
      end
    end

    def response_body(response)
      # Make sure we respect encoding because Net:HTTP will encode body as ASCII by default
      # which will break if the response is not compatible.
      supplied_charset = response.type_params["charset"]
      body = response.body

      if supplied_charset
        body.force_encoding(supplied_charset).encode!("UTF-8")
      else
        # Default to UTF-8 when server does not specify encoding as that is the
        # most common charset.
        body.force_encoding("UTF-8")
      end
    end
  end
end
