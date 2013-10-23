# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe Document do
    sample_html = "<html><body><p>Hello world!</p></body></html>"
    subject(:document) { described_class.new sample_html }

    it "is initialized with HTML" do
      doc = Document.new "<html></html>"
      doc.html.should == "<html></html>"
    end

    it "has an accessor for URL options" do
      document.url_options = {host: "foo.bar"}
      document.url_options.should == {host: "foo.bar"}
    end

    it "has a ProviderList" do
      document.asset_providers.should be_instance_of(ProviderList)
    end

    it "defaults to having just a FilesystemProvider in the provider list" do
      document.should have(1).asset_providers
      provider = document.asset_providers.first
      provider.should be_instance_of(FilesystemProvider)
    end

    it "allows changes to the asset providers" do
      other_provider = double "Other proider"
      old_list = document.asset_providers

      document.asset_providers = [other_provider]
      document.asset_providers.should be_instance_of(ProviderList)
      document.asset_providers.each.to_a.should == [other_provider]

      document.asset_providers = old_list
      document.asset_providers.should == old_list
    end

    it "can store callbacks for inlining" do
      callable = double "Callable"

      document.before_inlining = callable
      document.after_inlining = callable

      document.before_inlining.should == callable
      document.after_inlining.should == callable
    end

    describe "transforming" do
      it "runs the before and after callbacks" do
        document = Document.new "<body></body>"
        before = double call: nil
        after = double call: nil
        document.before_inlining = before
        document.after_inlining = after

        before.should_receive(:call).with(instance_of(Nokogiri::HTML::Document)).ordered
        Inliner.should_receive(:new).ordered.and_return double.as_null_object
        after.should_receive(:call).with(instance_of(Nokogiri::HTML::Document)).ordered

        document.transform
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

      result.should have_selector('html > head > title')
      result.at_css('title').text.should == "Greetings"

      result.should have_selector('html > body > p')
      paragraph = result.at_css('p')
      paragraph.text.should == "Hello, world!"
      paragraph.to_xml.should == '<p style="color:green">Hello, world!</p>'
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

      result.should have_styling([
        %w[color red],
        %w[text-align right],
        %w[color green],
        %w[text-size 2em]
      ]).at_selector("p")
    end
  end
end
