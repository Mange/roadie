# encoding: UTF-8
require 'spec_helper'

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
        before = ->{}
        after = ->{}
        document.before_transformation = before
        document.after_transformation = after

        expect(before).to receive(:call).with(instance_of(Nokogiri::HTML::Document), document).ordered
        expect(Inliner).to receive(:new).ordered.and_return double.as_null_object
        expect(after).to receive(:call).with(instance_of(Nokogiri::HTML::Document), document).ordered

        document.transform
      end

      # TODO: Remove on next major version.
      it "works on callables that don't expect more than one argument" do
        document = Document.new "<body></body>"
        document.before_transformation = ->(first) { }
        document.after_transformation = ->(first = nil) { }

        expect { document.transform }.to_not raise_error

        # It still supplies the second argument, if possible.
        document.after_transformation = ->(first, second = nil) {
          raise "Oops" unless second
        }
        expect { document.transform }.to_not raise_error
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

      expect(result).to have_selector('html > head > title')
      expect(result.at_css('title').text).to eq("Greetings")

      expect(result).to have_selector('html > body > p')
      paragraph = result.at_css('p')
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
        "/sample.css" => "p { color: red; text-align: right; }",
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
  end
end
