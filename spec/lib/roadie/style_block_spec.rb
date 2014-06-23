# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe StyleBlock do
    it "has a selector and a list of properties" do
      properties = []
      selector = double "Selector"

      block = StyleBlock.new(selector, properties)
      expect(block.selector).to eq(selector)
      expect(block.properties).to eq(properties)
    end

    it "delegates #specificity to the selector" do
      selector = double "Selector", specificity: 45
      expect(StyleBlock.new(selector, []).specificity).to eq(45)
    end

    it "delegates #inlinable? to the selector" do
      selector = double "Selector", inlinable?: "maybe"
      expect(StyleBlock.new(selector, []).inlinable?).to eq("maybe")
    end

    it "delegates #selector_string to selector#to_s" do
      selector = double "Selector", to_s: "yey"
      expect(StyleBlock.new(selector, []).selector_string).to eq("yey")
    end

    it "has a string representation" do
      properties = [double(to_s: "bar"), double(to_s: "baz")]
      expect(StyleBlock.new(double(to_s: "foo"), properties).to_s).to eq("foo{bar;baz}")
    end
  end
end
