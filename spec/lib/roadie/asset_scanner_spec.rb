# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe AssetScanner do
    let(:provider) { TestProvider.new }
    let(:dom) { dom_document "<html></html>" }

    def dom_fragment(html); Nokogiri::HTML.fragment html; end
    def dom_document(html); Nokogiri::HTML.parse html; end

    it "is initialized with a DOM tree and a asset provider set" do
      scanner = AssetScanner.new dom, provider
      expect(scanner.dom).to eq(dom)
      expect(scanner.asset_provider).to eq(provider)
    end

    describe "finding" do
      it "returns nothing when no stylesheets are referenced" do
        scanner = AssetScanner.new dom, provider
        expect(scanner.find_css).to eq([])
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
        scanner = AssetScanner.new dom, provider

        stylesheets = scanner.find_css

        expect(stylesheets).to have(2).stylesheets
        expect(stylesheets[0].to_s).to include("green")
        expect(stylesheets[1].to_s).to include("red")

        expect(stylesheets.first.name).to eq("(inline)")
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
        scanner = AssetScanner.new dom, provider
        expect(scanner.find_css).to have(1).stylesheet
      end

      it "finds referenced stylesheets through the provider" do
        stylesheet = double "A stylesheet"
        expect(provider).to receive(:find_stylesheet!).with("/some/url.css").and_return stylesheet

        dom = dom_fragment %(<link rel="stylesheet" href="/some/url.css">)
        scanner = AssetScanner.new dom, provider

        expect(scanner.find_css).to eq([stylesheet])
      end

      it "ignores referenced print stylesheets" do
        dom = dom_fragment %(<link rel="stylesheet" href="/error.css" media="print">)
        expect(provider).not_to receive(:find_stylesheet!)

        scanner = AssetScanner.new dom, provider

        expect(scanner.find_css).to eq([])
      end

      it "does not look for ignored referenced stylesheets" do
        dom = dom_fragment %(<link rel="stylesheet" href="/error.css" data-roadie-ignore>)
        expect(provider).not_to receive(:find_stylesheet!)

        scanner = AssetScanner.new dom, provider

        expect(scanner.find_css).to eq([])
      end

      it 'ignores HTML comments and CDATA sections' do
        # TinyMCE posts invalid CSS. We support that just to be pragmatic.
        dom = dom_fragment %(<style><![CDATA[
          <!--
          p { color: green }
          -->
        ]]></style>)

        scanner = AssetScanner.new dom, provider
        stylesheet = scanner.find_css.first

        expect(stylesheet.to_s).to include("green")
        expect(stylesheet.to_s).not_to include("!--")
        expect(stylesheet.to_s).not_to include("CDATA")
      end

      it "does not pick up scripts generating styles" do
        dom = dom_fragment <<-HTML
          <script>
            var color = "red";
            document.write("<style type='text/css'>p { color: " + color + "; }</style>");
          </script>
        HTML

        scanner = AssetScanner.new dom, provider
        expect(scanner.find_css).to eq([])
      end
    end

    describe "extracting" do
      it "returns the stylesheets found, and removes them from the DOM" do
        dom = dom_document <<-HTML
          <html>
            <head>
              <title>Hello world!</title>
              <style>span { color: green; }</style>
              <link rel="stylesheet" href="/some/url.css">
              <link rel="stylesheet" href="/error.css" media="print">
              <link rel="stylesheet" href="/cool.css" data-roadie-ignore>
            </head>
            <body>
              <style data-roadie-ignore>a { color: red; }</style>
            </body>
          </html>
        HTML
        provider = TestProvider.new "/some/url.css" => "body { color: green; }"
        scanner = AssetScanner.new dom, provider

        stylesheets = scanner.extract_css

        expect(stylesheets).to have(2).stylesheets
        expect(stylesheets[0].to_s).to include("span")
        expect(stylesheets[1].to_s).to include("body")

        expect(dom).to have_selector("html > head > title")
        expect(dom).to have_selector("html > body > style[data-roadie-ignore]")
        expect(dom).to have_selector("link[data-roadie-ignore]")
        expect(dom).to have_selector("link[media=print]")

        expect(dom).not_to have_selector("html > head > style")
        expect(dom).not_to have_selector("html > head > link[href='/some/url.css']")
      end
    end
  end
end
