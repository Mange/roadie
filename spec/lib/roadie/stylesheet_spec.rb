# frozen_string_literal: true

require "spec_helper"

module Roadie
  describe Stylesheet do
    it "is initialized with a name and CSS" do
      stylesheet = Stylesheet.new("foo.css", "body { color: green; }")
      expect(stylesheet.name).to eq("foo.css")
    end

    it "has a list of blocks" do
      stylesheet = Stylesheet.new("foo.css", <<-CSS)
        body { color: green !important; font-size: 200%; }
        a, i { color: red; }
      CSS
      expect(stylesheet).to have(3).blocks
      expect(stylesheet.blocks.map(&:to_s)).to eq([
        "body{color:green !important;font-size:200%}",
        "a{color:red}",
        "i{color:red}"
      ])
    end

    it "has a string representation of the contents" do
      stylesheet = Stylesheet.new("example.css", "body { color: green;}a{ color: red; font-size: small }")
      expect(stylesheet.to_s).to eq("body{color:green}\na{color:red;font-size:small}")
    end

    it "understands data URIs" do
      # http://css-tricks.com/data-uris/
      stylesheet = Stylesheet.new("foo.css", <<-CSS)
      h1 {
        background-image: url(data:image/gif;base64,R0lGODl)
      }
      CSS

      expect(stylesheet).to have(1).blocks
      expect(stylesheet.blocks.map(&:to_s)).to eq([
        "h1{background-image:url(data:image/gif;base64,R0lGODl)}"
      ])
    end

    it "does not mutate the input CSS" do
      input = "/* comment */ body { color: green; }"
      input_copy = input.dup
      expect {
        Stylesheet.new("name", input)
      }.to_not change { input }.from(input_copy)
    end

    it "strips UTF-8 Byte Order Mark" do
      input = "\xEF\xBB\xBFbody { color: green; }"
      stylesheet = Stylesheet.new("bom.css", input)
      expect(stylesheet.to_s).to eq "body{color:green}"
    end
  end
end
