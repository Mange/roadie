# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe MarkupImprover do
    def improve(html)
      dom = Nokogiri::HTML.parse html
      MarkupImprover.new(dom).improve
      dom
    end

    it "inserts <head> if not present" do
      improve('<html><body></body></html>').should have_selector('html > head + body')
    end

    it "inserts meta tag describing content-type" do
      dom = improve('<html><head></head><body></body></html>')

      dom.should have_selector('head meta')
      meta = dom.at_css('head meta')
      meta['http-equiv'].should == 'Content-Type'
      meta['content'].should == 'text/html; charset=UTF-8'
    end

    it "does not insert duplicate meta tags describing content-type" do
      improve(<<-HTML).xpath('//meta').should have(1).item
      <html>
        <head>
          <meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
        </head>
      </html>
      HTML
    end

    # These are "features" of Nokogiri (or rather libxml) that we cannot even
    # turn off. Just by parsing the HTML, an <html> and <body> element is
    # introduced for example. These examples are here just in case Nokogiri
    # changes its behavior in a later version, and/or if Roadie ever starts
    # using another backend.
    describe "(inherent improvement)" do
      it "inserts a doctype if not present" do
        # TODO: See if it is possible to always make it into a HTML5 doctype
        improve('<html><body></body></html>').to_html.should include('<!DOCTYPE ')
      end

      it "does not add a doctype if another is already specified" do
        html = improve('<!DOCTYPE html><html><body></body></html>').to_html
        html.scan('DOCTYPE').size.should == 1
        # Make sure it's unchanged
        html.should include('<!DOCTYPE html>')
      end

      it "inserts basic html structure if not present" do
        improve('<h1>Hey!</h1>').should have_selector('html > head + body > h1')
      end
    end
  end
end
