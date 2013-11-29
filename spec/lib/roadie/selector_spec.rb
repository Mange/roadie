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
        p:-ms-input-placeholder
        p:-moz-placeholder
        p:before
        p:after
        p:enabled
        p:disabled
        p:checked
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

    it "has a calculated specificity" do
      selector = "html p.active.nice #main.deep-selector"
      Selector.new(selector).specificity.should == CssParser.calculate_specificity(selector)
    end

    it "is equal to other selectors when they match the same things" do
      Selector.new("foo").should == Selector.new("foo ")
      Selector.new("foo").should_not == "foo"
    end

    it "strips the given selector" do
      Selector.new(" foo  \n").to_s.should == Selector.new("foo").to_s
    end
  end
end
