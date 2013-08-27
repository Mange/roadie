module Roadie
  class InvalidUrlPath < RuntimeError
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
end
