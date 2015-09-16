# encoding: UTF-8
require 'set'
require 'uri'
require 'net/http'
require 'net/https' # For Ruby 1.9.3 support

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
      if response.kind_of? Net::HTTPSuccess
        Stylesheet.new url, response.body
      else
        raise CssNotFound.new(url, "Server returned #{response.code}: #{truncate response.body}", self)
      end
    rescue Timeout::Error
      raise CssNotFound.new(url, "Timeout", self)
    end

    def to_s() inspect end
    def inspect() "#<#{self.class} whitelist: #{whitelist.inspect}>" end

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
        raise CssNotFound.new(url, "#{uri.host} is not part of whitelist!", self)
      end
    end

    def get_response(uri)
      if RUBY_VERSION >= "2.0.0"
        Net::HTTP.get_response(uri)
      else
        Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
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
  end
end
