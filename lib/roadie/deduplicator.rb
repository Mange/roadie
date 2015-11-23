module Roadie
  class Deduplicator
    def self.apply(input)
      new(input).apply
    end

    def initialize(input)
      @input = input
      @duplicates = false
    end

    def apply
      # Bail early for very small inputs
      input if input.size < 2

      calculate_latest_occurance

      # Another early bail in case we never even have a duplicate value
      if has_duplicates?
        strip_out_duplicates
      else
        input
      end
    end

    private
    attr_reader :input, :latest_occurance

    def has_duplicates?
      @duplicates
    end

    def calculate_latest_occurance
      @latest_occurance = input.each_with_index.each_with_object({}) do |(value, index), map|
        @duplicates = true if map.has_key?(value)
        map[value] = index
      end
    end

    def strip_out_duplicates
      input.each_with_index.select { |value, index|
        latest_occurance[value] == index
      }.map(&:first)
    end
  end
end
