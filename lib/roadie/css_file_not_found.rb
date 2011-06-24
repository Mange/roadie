module Roadie
  # Raised when a stylesheet specified for inlining is not present.
  # You can access the target filename via #filename.
  class CSSFileNotFound < StandardError
    attr_reader :filename, :guess

    def initialize(filename, guess = nil)
      @filename = filename
      @guess = guess
      super(build_message)
    end

    private
      def build_message
        if guess
          "Could not find #{filename} (guessed from #{guess.inspect})"
        else
          "Could not find #{filename}"
        end
      end
  end
end
