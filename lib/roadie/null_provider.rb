module Roadie
  # An asset provider that returns empty stylesheets for any name.
  #
  # Use it to ignore missing assets or in your tests when you need a provider
  # but you do not care what it contains or that it is even referenced at all.
  class NullProvider
    def find_stylesheet(name) empty_stylesheet end
    def find_stylesheet!(name) empty_stylesheet end

    def to_s() inspect end
    def inspect() "#<#{self.class}>" end

    private
    def empty_stylesheet() Stylesheet.new "(null)", "" end
  end
end
