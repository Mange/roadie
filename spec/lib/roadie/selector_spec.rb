# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe Selector do
    it "can be coerced into String" do
      ("I love " + Selector.new("html")).should == "I love html"
    end

    it "can be inlined when simple" do
      Selector.new("html body #main p.class").should be_inlinable
    end

    it "cannot be inlined when containing pseudo functions" do
      %w[
        p:active
        p:focus
        p:hover
        p:link
        p:target
        p:visited
      ].each do |bad_selector|
        Selector.new(bad_selector).should_not be_inlinable
      end

      Selector.new('p.active').should be_inlinable
    end

    it "cannot be inlined when containing pseudo elements" do
      Selector.new('p::some-element').should_not be_inlinable
    end

    it "cannot be inlined when selector is an at-rule" do
      Selector.new('@keyframes progress-bar-stripes').should_not be_inlinable
    end
  end
end
