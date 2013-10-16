# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe Stylesheet do
    it "is initialized with a name and CSS" do
      stylesheet = Stylesheet.new("foo.css", "body { color: green; }")
      stylesheet.name.should == "foo.css"
    end

    it "has a list of blocks" do
      stylesheet = Stylesheet.new("foo.css", <<-CSS)
        body { color: green !important; font-size: 200%; }
        a, i { color: red; }
      CSS
      stylesheet.should have(3).blocks
      stylesheet.blocks.map(&:to_s).should == [
        "body{color:green !important;font-size:200%}",
        "a{color:red}",
        "i{color:red}",
      ]
    end

    it "can iterate all inlinable blocks" do
      inlinable = double(inlinable?: true, selector: "good", properties: "props")
      bad = double(inlinable?: false, selector: "bad", properties: "props")

      stylesheet = Stylesheet.new("example.css", "")
      stylesheet.stub blocks: [bad, inlinable, bad]

      stylesheet.each_inlinable_block.to_a.should == [
        ["good", "props"],
      ]
    end

    it "has a string representation of the contents" do
      stylesheet = Stylesheet.new("example.css", "body { color: green;}a{ color: red; font-size: small }")
      stylesheet.to_s.should == "body{color:green}\na{color:red;font-size:small}"
    end
  end
end
