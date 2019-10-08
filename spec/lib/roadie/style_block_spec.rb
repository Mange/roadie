# frozen_string_literal: true

require 'spec_helper'

module Roadie
  describe StyleBlock do
    it "has a selector and a list of properties" do
      properties = []
      selector = double "Selector"

      block = StyleBlock.new(selector, properties, [:all])
      expect(block.selector).to eq(selector)
      expect(block.properties).to eq(properties)
    end

    it "delegates #specificity to the selector" do
      selector = double "Selector", specificity: 45
      expect(StyleBlock.new(selector, [], [:all]).specificity).to eq(45)
    end

    it "delegates #selector_string to selector#to_s" do
      selector = double "Selector", to_s: "yey"
      expect(StyleBlock.new(selector, [], [:all]).selector_string).to eq("yey")
    end

    it "has a string representation" do
      properties = [double(to_s: "bar"), double(to_s: "baz")]
      expect(StyleBlock.new(double(to_s: "foo"), properties, [:all]).to_s).to eq("foo{bar;baz}")
    end

    describe "#inlinable" do
      context "when no media include feature condition" do
        it "delegates #inlinable? to the selector" do
          selector = double "Selector", inlinable?: "maybe"
          expect(StyleBlock.new(selector, [], [:all]).inlinable?).to eq("maybe")
        end
      end

      context "when one of media queries includes feature condition" do
        it "returns false" do
          selector = double "Selector", inlinable?: "maybe"
          expect(StyleBlock.new(selector, [], [:all, :'screen (min-width: 300px)']).inlinable?).to be(false)
        end
      end
    end
  end
end
