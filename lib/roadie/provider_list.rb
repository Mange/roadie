require 'forwardable'

module Roadie
  # An asset provider that just composes a list of other asset providers.
  #
  # Give it a list of providers and they will all be tried in order.
  #
  # {ProviderList} behaves like an Array, *and* an asset provider, and can be coerced into an array.
  class ProviderList
    extend Forwardable
    include Enumerable

    # Wrap a single provider, or a list of providers into a {ProviderList}.
    #
    # @overload wrap(provider_list)
    #   @param [ProviderList] provider_list An actual instance of {ProviderList}.
    #   @return The passed in provider_list
    #
    # @overload wrap(provider)
    #   @param [asset provider] provider
    #   @return a new {ProviderList} with just the passed provider in it
    #
    # @overload wrap(provider1, provider2, ...)
    #   @return a new {ProviderList} with all the passed providers in it.
    def self.wrap(*providers)
      if providers.size == 1 && providers.first.class == self
        providers.first
      else
        new(providers.flatten)
      end
    end

    # Returns a new empty list.
    def self.empty() new([]) end

    def initialize(providers)
      @providers = providers
    end

    # @return [Stylesheet, nil]
    def find_stylesheet(name)
      @providers.each do |provider|
        css = provider.find_stylesheet(name)
        return css if css
      end
      nil
    end

    # Tries to find the given stylesheet and raises an {ProvidersFailed} error
    # if no provider could find the asset.
    #
    # @return [Stylesheet]
    def find_stylesheet!(name)
      errors = []
      @providers.each do |provider|
        begin
          return provider.find_stylesheet!(name)
        rescue CssNotFound => error
          errors << error
        end
      end
      raise ProvidersFailed.new(name, self, errors)
    end

    def to_s
      list = @providers.map { |provider|
        # Indent every line one level
        provider.to_s.split("\n").join("\n\t")
      }
      "ProviderList: [\n\t#{list.join(",\n\t")}\n]"
    end

    # ProviderList can be coerced to an array. This makes Array#flatten work
    # with it, among other things.
    def to_ary() to_a end

    # @!method each
    #   @see Array#each
    # @!method size
    #   @see Array#size
    # @!method empty?
    #   @see Array#empty?
    # @!method push
    #   @see Array#push
    # @!method <<
    #   @see Array#<<
    # @!method pop
    #   @see Array#pop
    # @!method unshift
    #   @see Array#unshift
    # @!method shift
    #   @see Array#shift
    # @!method last
    #   @see Array#last
    def_delegators :@providers, :each, :size, :empty?, :push, :<<, :pop, :unshift, :shift, :last
  end
end
