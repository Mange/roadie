# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe MarkupImprover do
    def improve(html)
      dom = Nokogiri::HTML.parse html
      MarkupImprover.new(dom, html).improve
      dom
    end

    # JRuby up to at least 1.6.0 has a bug where the doctype of a document cannot be changed.
    # See https://github.com/sparklemotion/nokogiri/issues/984
    def pending_for_buggy_jruby
      # No reason to check for version yet since no existing version has a fix.
      pending "Pending until Nokogiri issue #984 is fixed and released" if defined?(JRuby)
    end

    describe "automatic doctype" do
      it "inserts a HTML5 doctype if no doctype is present" do
        pending_for_buggy_jruby
        improve("<html></html>").internal_subset.to_xml.should == "<!DOCTYPE html>"
      end

      it "does not insert duplicate doctypes" do
        html = improve('<!DOCTYPE html><html><body></body></html>').to_html
        html.scan('DOCTYPE').size.should == 1
      end

      it "leaves other doctypes alone" do
        dtd = "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">"
        html = "#{dtd}<html></html>"
        improve(html).internal_subset.to_xml.strip.should == dtd
      end
    end

    describe "basic HTML structure" do
      it "inserts a <html> element as the root" do
        improve("<h1>Hey!</h1>").should have_selector("html h1")
        improve("<html></html>").css('html').size.should == 1
      end

      it "inserts <head> if not present" do
        improve('<html><body></body></html>').should have_selector('html > head + body')
        improve('<html></html>').should have_selector('html > head')
        improve('Foo').should have_selector('html > head')
        improve('<html><head></head></html>').css('head').size.should == 1
      end

      it "inserts <body> if not present" do
        improve('<h1>Hey!</h1>').should have_selector('html > body > h1')
        improve('<html><h1>Hey!</h1></html>').should have_selector('html > body > h1')
        improve('<html><body><h1>Hey!</h1></body></html>').css('body').size.should == 1
      end
    end

    describe "charset declaration" do
      it "is inserted if missing" do
        dom = improve('<html><head></head><body></body></html>')

        dom.should have_selector('head meta')
        meta = dom.at_css('head meta')
        meta['http-equiv'].should == 'Content-Type'
        meta['content'].should == 'text/html; charset=UTF-8'
      end

      it "is left alone when predefined" do
        improve(<<-HTML).xpath('//meta').should have(1).item
        <html>
          <head>
            <meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
          </head>
        </html>
        HTML
      end
    end
  end
end
