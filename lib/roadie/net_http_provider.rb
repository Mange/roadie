require 'set'
require 'uri'
require 'net/http'

module Roadie
  # External asset provider that downloads stylesheets from some other server
  # using Ruby's built-in {Net::HTTP} library.
  #
  # You can pass a whitelist of hosts that downloads are allowed on.
  class NetHttpProvider
    attr_reader :whitelist

    # @option options [Array<String>] :whitelist ([]) A list of host names that downloads are allowed from. Empty set means everything is allowed.
    def initialize(options = {})
      @whitelist = Array(options.fetch(:whitelist, [])).to_set
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
    def download(url)
      uri = URI.parse(url)
      if access_granted_to?(uri.host)
        Net::HTTP.get_response(uri)
      else
        raise CssNotFound.new(url, "#{uri.host} is not part of whitelist!", self)
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
