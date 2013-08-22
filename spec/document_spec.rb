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

    it "defaults to the FilesystemProvider" do
      document.should have(1).asset_providers
      provider = document.asset_providers.first
      provider.should be_instance_of(FilesystemProvider)
    end

    it "allows changes to the asset providers" do
      other_provider = double "Other proider"
      document.asset_providers = [other_provider]
      document.asset_providers.should == [other_provider]
    end

    it "can store callbacks for inlining" do
      callable = double "Callable"

      document.before_inlining = callable
      document.after_inlining = callable

      document.before_inlining.should == callable
      document.after_inlining.should == callable
    end
  end

  describe Document, "integration" do
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
  end
end
