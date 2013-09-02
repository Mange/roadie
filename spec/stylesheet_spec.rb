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
      inlinable = double(inlinable?: true)
      bad = double(inlinable?: false)

      stylesheet = Stylesheet.new("example.css", "")
      stylesheet.stub blocks: [bad, inlinable, bad]

      stylesheet.each_inlinable_block.to_a.should == [inlinable]
    end
  end
end
