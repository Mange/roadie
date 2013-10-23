module Roadie
  Error = Class.new(RuntimeError)

  UnparseableDeclaration = Class.new(Error)

  class InvalidUrlPath < Error
    attr_reader :cause

    def initialize(given_path, cause = nil)
      @cause = cause
      if cause
        cause_message = " Caused by: #{cause}"
      else
        cause_message = ""
      end
      super "Cannot use path \"#{given_path}\" in URL generation.#{cause_message}"
    end
  end

  class CssNotFound < Error
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
