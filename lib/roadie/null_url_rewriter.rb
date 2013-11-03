module Roadie
  # @api private
  # Null Object for the URL rewriter role.
  #
  # Used whenever client does not pass any URL options and no URL rewriting
  # should take place.
  class NullUrlRewriter
    def initialize(generator = nil) end
    def transform_dom(dom) end
    def transform_css(css) end
  end
end
