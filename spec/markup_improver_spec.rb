# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe MarkupImprover do
    def improve(html)
      dom = Nokogiri::HTML.parse html
      MarkupImprover.new(dom).improve
      dom
    end

    it "inserts a doctype if not present" do
      improve('<html><body></body></html>').to_xml.should include('<!DOCTYPE ')
      improve('<!DOCTYPE html><html><body></body></html>').to_xml.should_not match(/(DOCTYPE.*?){2}/)
    end

    it "sets xmlns of <html> to that of XHTML" do
      improve('<html><body></body></html>').should have_node('html').with_attributes("xmlns" => "http://www.w3.org/1999/xhtml")
    end

    # This is a "feature" of Nokogiri (or rather libxml) that we cannot even
    # turn off. Just by parsing the HTML, an <html> and <body> element is
    # introduced. This spec is here just in case Nokogiri changes its
    # behavior in a later version, and/or if Roadie ever starts using another
    # backend.
    it "inserts basic html structure if not present" do
      improve('<h1>Hey!</h1>').should have_selector('html > head + body > h1')
    end

    it "inserts <head> if not present" do
      improve('<html><body></body></html>').should have_selector('html > head + body')
    end

    it "inserts meta tag describing content-type" do
      improve('<html><head></head><body></body></html>').tap do |dom|
        dom.should have_selector('head meta[http-equiv="Content-Type"]')
        dom.css('head meta[http-equiv="Content-Type"]').first['content'].should == 'text/html; charset=UTF-8'
      end
    end

    it "does not insert duplicate meta tags describing content-type" do
      improve(<<-HTML).to_html.scan('meta').should have(1).item
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
        </head>
      </html>
      HTML
    end
  end
end
