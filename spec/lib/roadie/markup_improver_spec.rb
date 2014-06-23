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
      skip "Pending until Nokogiri issue #984 is fixed and released" if defined?(JRuby)
    end

    describe "automatic doctype" do
      it "inserts a HTML5 doctype if no doctype is present" do
        pending_for_buggy_jruby
        expect(improve("<html></html>").internal_subset.to_xml).to eq("<!DOCTYPE html>")
      end

      it "does not insert duplicate doctypes" do
        html = improve('<!DOCTYPE html><html><body></body></html>').to_html
        expect(html.scan('DOCTYPE').size).to eq(1)
      end

      it "leaves other doctypes alone" do
        dtd = "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">"
        html = "#{dtd}<html></html>"
        expect(improve(html).internal_subset.to_xml.strip).to eq(dtd)
      end
    end

    describe "basic HTML structure" do
      it "inserts a <html> element as the root" do
        expect(improve("<h1>Hey!</h1>")).to have_selector("html h1")
        expect(improve("<html></html>").css('html').size).to eq(1)
      end

      it "inserts <head> if not present" do
        expect(improve('<html><body></body></html>')).to have_selector('html > head + body')
        expect(improve('<html></html>')).to have_selector('html > head')
        expect(improve('Foo')).to have_selector('html > head')
        expect(improve('<html><head></head></html>').css('head').size).to eq(1)
      end

      it "inserts <body> if not present" do
        expect(improve('<h1>Hey!</h1>')).to have_selector('html > body > h1')
        expect(improve('<html><h1>Hey!</h1></html>')).to have_selector('html > body > h1')
        expect(improve('<html><body><h1>Hey!</h1></body></html>').css('body').size).to eq(1)
      end
    end

    describe "charset declaration" do
      it "is inserted if missing" do
        dom = improve('<html><head></head><body></body></html>')

        expect(dom).to have_selector('head meta')
        meta = dom.at_css('head meta')
        expect(meta['http-equiv']).to eq('Content-Type')
        expect(meta['content']).to eq('text/html; charset=UTF-8')
      end

      it "is left alone when predefined" do
        expect(improve(<<-HTML).xpath('//meta')).to have(1).item
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
