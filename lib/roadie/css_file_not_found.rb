module Roadie
  # Raised when a stylesheet specified for inlining is not present.
  # You can access the target filename via #filename.
  class CSSFileNotFound < StandardError
    attr_reader :filename

    def initialize(filename)
      @filename = filename
      super("Could not find #{filename}")
    end
  end
end
