# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe StyleProperties do
    it "has a list of properties" do
      property = StyleProperty.new("color", "green", false, 1)
      expect(StyleProperties.new([property]).properties).to eq([property])
    end

    it "can be merged with other properties" do
      old = StyleProperty.new("color", "red", false, 1)
      new = StyleProperty.new("color", "green", false, 5)
      instance = StyleProperties.new([old])

      expect(instance.merge(StyleProperties.new([new])).properties).to eq([old, new])
      expect(instance.merge([new]).properties).to eq([old, new])

      # Original is not mutated
      expect(instance.properties).to eq([old])
    end

    it "can be destructively merged with other properties" do
      old = StyleProperty.new("color", "red", false, 1)
      new = StyleProperty.new("color", "green", false, 5)
      instance = StyleProperties.new([old])

      instance.merge!([new])
      expect(instance.properties).to eq([old, new])
    end

    describe "string representation" do
      class MockProperty
        attr_reader :sort_value
        include Comparable

        def initialize(name, sort_value = 0)
          @name, @sort_value = name, sort_value
        end

        def <=>(other) @sort_value <=> other.sort_value end
        def to_s() @name.to_s end
      end

      it "joins properties together with semicolons" do
        property = MockProperty.new("foo:bar")
        expect(StyleProperties.new([property, property]).to_s).to eq("foo:bar;foo:bar")
      end

      it "sorts properties" do
        important = MockProperty.new("super important", 100)
        insignificant = MockProperty.new("insignificant", 2)
        common = MockProperty.new("common", 20)

        expect(StyleProperties.new(
          [important, insignificant, common]
        ).to_s).to eq("insignificant;common;super important")
      end
    end
  end
end
