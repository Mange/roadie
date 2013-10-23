# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe StyleBlock do
    it "has a selector and a list of properties" do
      properties = []
      selector = double "Selector"

      block = StyleBlock.new(selector, properties)
      block.selector.should == selector
      block.properties.should == properties
    end

    it "delegates #specificity to the selector" do
      selector = double "Selector", specificity: 45
      StyleBlock.new(selector, []).specificity.should == 45
    end

    it "delegates #inlinable? to the selector" do
      selector = double "Selector", inlinable?: "maybe"
      StyleBlock.new(selector, []).inlinable?.should == "maybe"
    end

    it "delegates #selector_string to selector#to_s" do
      selector = double "Selector", to_s: "yey"
      StyleBlock.new(selector, []).selector_string.should == "yey"
    end

    it "has a string representation" do
      properties = [double(to_s: "bar"), double(to_s: "baz")]
      StyleBlock.new(double(to_s: "foo"), properties).to_s.should == "foo{bar;baz}"
    end
  end
end
