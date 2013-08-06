# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe AssetScanner do
    # TODO: Implement a TestProvider and use it in a real set
    let(:providers) { double("Asset provider set") }
    let(:dom) { dom_document "<html></html>" }

    def dom_fragment(html); Nokogiri::HTML.fragment html; end
    def dom_document(html); Nokogiri::HTML.parse html; end

    it "is initialized with a DOM tree and a asset provider set" do
      scanner = AssetScanner.new dom, providers
      scanner.dom.should == dom
      scanner.asset_providers.should == providers
    end

    describe "finding" do
      it "returns nothing when no stylesheets are referenced" do
        scanner = AssetScanner.new dom, providers
        scanner.find_css.should == []
      end

      it "finds all embedded stylesheets" do
        dom = dom_document <<-HTML
          <html>
            <head>
              <style>a { color: green; }</style>
            </head>
            <body>
              <style>
                body { color: red; }
              </style>
            </body>
          </html>
        HTML
        scanner = AssetScanner.new dom, providers
        scanner.find_css.should == [
          "a { color: green; }",
          "body { color: red; }",
        ]
      end

      it "does not find any embedded stylesheets marked for ignoring" do
        dom = dom_document <<-HTML
          <html>
            <head>
              <style>a { color: green; }</style>
              <style data-roadie-ignore>a { color: red; }</style>
            </head>
          </html>
        HTML
        scanner = AssetScanner.new dom, providers
        scanner.find_css.should == ["a { color: green; }"]
      end

      it "finds referenced stylesheets through the providers" do
        providers.should_receive(:find_stylesheet).with(
          "/some/url.css"
        ).and_return "p { color: green; }"
        dom = dom_fragment %(<link rel="stylesheet" src="/some/url.css">)

        scanner = AssetScanner.new dom, providers

        scanner.find_css.should == ["p { color: green; }"]
      end

      it "ignores referenced print stylesheets" do
        dom = dom_fragment %(<link rel="stylesheet" src="/error.css" media="print">)
        providers.should_not_receive(:find_stylesheet)

        scanner = AssetScanner.new dom, providers

        scanner.find_css.should == []
      end

      it "does not look for ignored referenced stylesheets" do
        dom = dom_fragment %(<link rel="stylesheet" src="/error.css" data-roadie-ignore>)
        providers.should_not_receive(:find_stylesheet)

        scanner = AssetScanner.new dom, providers

        scanner.find_css.should == []
      end
    end

    describe "extracting" do
      it "returns the stylesheets found, and removes them from the DOM" do
        dom = dom_document <<-HTML
          <html>
            <head>
              <title>Hello world!</title>
              <style>a { color: green; }</style>
              <link rel="stylesheet" src="/some/url.css">
              <link rel="stylesheet" src="/error.css" media="print">
              <link rel="stylesheet" src="/cool.css" data-roadie-ignore>
            </head>
            <body>
              <style data-roadie-ignore>a { color: red; }</style>
            </body>
          </html>
        HTML
        providers.stub find_stylesheet: "body { color: green; }"

        scanner = AssetScanner.new dom, providers

        scanner.extract_css.should == [
          "a { color: green; }",
          "body { color: green; }",
        ]
        dom.should have_selector("html > head > title")
        dom.should have_selector("html > body > style[data-roadie-ignore]")
        dom.should have_selector("link[data-roadie-ignore]")
        dom.should have_selector("link[media=print]")

        dom.should_not have_selector("html > head > style")
        dom.should_not have_selector("html > head > link[src='/some/url.css']")
      end
    end
  end
end
