require "spec_helper"

module Roadie
  describe Deduplicator do
    it "removes identical pairs, keeping the last one" do
      input = [
        ["a", "1"],
        ["b", "2"],
        ["a", "3"],
        ["a", "1"],
      ]

      expect(Deduplicator.apply(input)).to eq [
        ["b", "2"],
        ["a", "3"],
        ["a", "1"],
      ]
    end

    it "returns input when no duplicates are present" do
      input = [
        ["a", "1"],
        ["a", "3"],
        ["a", "2"],
      ]

      expect(Deduplicator.apply(input)).to eq input
    end
  end
end
