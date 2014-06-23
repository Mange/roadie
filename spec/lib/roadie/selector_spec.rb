# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe Selector do
    it "can be coerced into String" do
      expect("I love " + Selector.new("html")).to eq("I love html")
    end

    it "can be inlined when simple" do
      expect(Selector.new("html body #main p.class")).to be_inlinable
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
        expect(Selector.new(bad_selector)).not_to be_inlinable
      end

      expect(Selector.new('p.active')).to be_inlinable
    end

    it "cannot be inlined when containing pseudo elements" do
      expect(Selector.new('p::some-element')).not_to be_inlinable
    end

    it "cannot be inlined when selector is an at-rule" do
      expect(Selector.new('@keyframes progress-bar-stripes')).not_to be_inlinable
    end

    it "has a calculated specificity" do
      selector = "html p.active.nice #main.deep-selector"
      expect(Selector.new(selector).specificity).to eq(CssParser.calculate_specificity(selector))
    end

    it "can be told about the specificity at initialization" do
      selector = "html p.active.nice #main.deep-selector"
      expect(Selector.new(selector, 1337).specificity).to eq(1337)
    end

    it "is equal to other selectors when they match the same things" do
      expect(Selector.new("foo")).to eq(Selector.new("foo "))
      expect(Selector.new("foo")).not_to eq("foo")
    end

    it "strips the given selector" do
      expect(Selector.new(" foo  \n").to_s).to eq(Selector.new("foo").to_s)
    end
  end
end
