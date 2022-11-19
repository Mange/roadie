# frozen_string_literal: true

require "spec_helper"

module Roadie
  describe Document do
    sample_html = "<html><body><p>Hello world!</p></body></html>"
    subject(:document) { described_class.new sample_html }

    it "is initialized with HTML" do
      doc = Document.new "<html></html>"
      expect(doc.html).to eq("<html></html>")
    end

    it "has an accessor for URL options" do
      document.url_options = {host: "foo.bar"}
      expect(document.url_options).to eq({host: "foo.bar"})
    end

    it "has an accessor for serialization options" do
      serialization_options = Nokogiri::XML::Node::SaveOptions::FORMAT |
        Nokogiri::XML::Node::SaveOptions::NO_EMPTY_TAGS
      document.serialization_options = serialization_options
      expect(document.serialization_options).to eq(serialization_options)

      document.serialization_options = nil
      expect(document.serialization_options).to eq(0)
    end

    it "has a setting for keeping uninlinable styles" do
      expect(document.keep_uninlinable_css).to be true
      document.keep_uninlinable_css = false
      expect(document.keep_uninlinable_css).to be false
    end

    it "has a ProviderList for normal and external providers" do
      expect(document.asset_providers).to be_instance_of(ProviderList)
      expect(document.external_asset_providers).to be_instance_of(ProviderList)
    end

    it "defaults to having just a FilesystemProvider in the normal provider list" do
      expect(document).to have(1).asset_providers
      expect(document).to have(0).external_asset_providers

      provider = document.asset_providers.first
      expect(provider).to be_instance_of(FilesystemProvider)
    end

    it "defaults to HTML mode" do
      expect(document.mode).to eq(:html)
    end

    it "allows changes to the normal asset providers" do
      other_provider = double "Other proider"
      old_list = document.asset_providers

      document.asset_providers = [other_provider]
      expect(document.asset_providers).to be_instance_of(ProviderList)
      expect(document.asset_providers.each.to_a).to eq([other_provider])

      document.asset_providers = old_list
      expect(document.asset_providers).to eq(old_list)
    end

    it "allows changes to the external asset providers" do
      other_provider = double "Other proider"
      old_list = document.external_asset_providers

      document.external_asset_providers = [other_provider]
      expect(document.external_asset_providers).to be_instance_of(ProviderList)
      expect(document.external_asset_providers.each.to_a).to eq([other_provider])

      document.external_asset_providers = old_list
      expect(document.external_asset_providers).to eq(old_list)
    end

    it "allows changes to the mode setting" do
      document.mode = :xhtml
      expect(document.mode).to eq(:xhtml)

      document.mode = :html
      expect(document.mode).to eq(:html)

      document.mode = :xml
      expect(document.mode).to eq(:xml)
    end

    it "does not allow unknown modes" do
      expect {
        document.mode = :other
      }.to raise_error(ArgumentError, /:other/)
    end

    it "can store callbacks for inlining" do
      callable = double "Callable"

      document.before_transformation = callable
      document.after_transformation = callable

      expect(document.before_transformation).to eq(callable)
      expect(document.after_transformation).to eq(callable)
    end

    describe "transforming" do
      it "runs the before and after callbacks" do
        document = Document.new "<body></body>"
        before = -> {}
        after = -> {}
        document.before_transformation = before
        document.after_transformation = after

        expect(before).to receive(:call).with(instance_of(Nokogiri::HTML::Document), document).ordered
        expect(Inliner).to receive(:new).ordered.and_return double.as_null_object
        expect(after).to receive(:call).with(instance_of(Nokogiri::HTML::Document), document).ordered

        document.transform
      end

      context "in HTML mode" do
        it "does not escape curly braces" do
          document = Document.new "<body><a href='https://google.com/{{hello}}'>Hello</a></body>"
          document.mode = :xhtml

          expect(document.transform).to include("{{hello}}")
        end
      end

      context "in XML mode" do
        it "doesn't replace empty tags with self-closed ones" do
          document = Document.new "<img src='https://google.com/image.png'></img>"
          document.mode = :xml

          expect(document.transform_partial).to end_with("</img>")
        end

        it "does not escape curly braces" do
          document = Document.new "<a href='https://google.com/{{hello}}'>Hello</a>"
          document.mode = :xml
          expect(document.transform_partial).to include("{{hello}}")
        end
      end
    end

    describe "partial transforming" do
      it "runs the before and after callbacks" do
        document = Document.new "<p></p>"
        before = -> {}
        after = -> {}
        document.before_transformation = before
        document.after_transformation = after

        expect(before).to receive(:call).with(
          instance_of(Nokogiri::HTML::DocumentFragment),
          document
        ).ordered

        expect(Inliner).to receive(:new).ordered.and_return double.as_null_object

        expect(after).to receive(:call).with(
          instance_of(Nokogiri::HTML::DocumentFragment),
          document
        ).ordered

        document.transform_partial
      end

      context "in HTML mode" do
        it "does not escape curly braces" do
          document = Document.new "<a href='https://google.com/{{hello}}'>Hello</a>"
          document.mode = :xhtml

          expect(document.transform_partial).to include("{{hello}}")
        end
      end

      context "in XML mode" do
        it "doesn't replace empty tags with self-closed ones" do
          document = Document.new "<img src='https://google.com/image.png'></img>"
          document.mode = :xml

          expect(document.transform_partial).to end_with("</img>")
        end

        it "does not escape curly braces" do
          document = Document.new "<a href='https://google.com/{{hello}}'>Hello</a>"
          document.mode = :xml
          expect(document.transform_partial).to include("{{hello}}")
        end
      end
    end
  end

  describe Document, "(integration)" do
    it "can transform the document" do
      document = Document.new <<-HTML
        <html>
          <head>
            <title>Greetings</title>
          </head>
          <body>
            <p>Hello, world!</p>
          </body>
        </html>
      HTML

      document.add_css "p { color: green; }"

      result = Nokogiri::HTML.parse document.transform

      expect(result).to have_selector("html > head > title")
      expect(result.at_css("title").text).to eq("Greetings")

      expect(result).to have_selector("html > body > p")
      paragraph = result.at_css("p")
      expect(paragraph.text).to eq("Hello, world!")
      expect(paragraph.to_xml).to eq('<p style="color:green">Hello, world!</p>')
    end

    it "extracts styles from the HTML" do
      document = Document.new <<-HTML
        <html>
          <head>
            <title>Greetings</title>
            <link rel="stylesheet" href="/sample.css" type="text/css">
          </head>
          <body>
            <p>Hello, world!</p>
          </body>
        </html>
      HTML

      document.asset_providers = TestProvider.new({
        "/sample.css" => "p { color: red; text-align: right; }"
      })

      document.add_css "p { color: green; text-size: 2em; }"

      result = Nokogiri::HTML.parse document.transform

      expect(result).to have_styling([
        %w[color red],
        %w[text-align right],
        %w[color green],
        %w[text-size 2em]
      ]).at_selector("p")
    end

    it "removes data-roadie-ignore markers" do
      document = Document.new <<-HTML
        <html>
          <head>
            <link rel="stylesheet" href="/cool.css" data-roadie-ignore id="first">
          </head>
          <body>
            <style data-roadie-ignore id="second">a { color: red; }</style>
            <a href="#" data-roadie-ignore>
              Hello world!
              <span data-roadie-ignore></span>
            </a>
          </body>
        </html>
      HTML

      result = Nokogiri::HTML.parse document.transform

      expect(result).to have_selector("body > a > span")
      expect(result).not_to have_selector("[data-roadie-ignore]")
    end
  end
end
