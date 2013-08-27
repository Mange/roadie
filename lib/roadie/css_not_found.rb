module Roadie
  # Raised when a stylesheet specified for inlining is not present.
  # You can access the target filename via #filename.
  class CssNotFound < StandardError
    attr_reader :css_name

    def initialize(css_name, extra_message = nil)
      @css_name = css_name
      super build_message(extra_message)
    end

    private
      def build_message(extra_message)
        if extra_message
          %(Could not find stylesheet "#{css_name}": #{extra_message})
        else
          %(Could not find stylesheet "#{css_name}")
        end
      end
  end
end
