module Roadie
  class NullProvider
    def find_stylesheet(name) empty_stylesheet end
    def find_stylesheet!(name) empty_stylesheet end

    private
    def empty_stylesheet() Stylesheet.new "(null)", "" end
  end
end
