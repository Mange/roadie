require 'spec_helper'

module Roadie
  describe UrlRewriter do
    describe "transforming DOM trees" do
      def dom_document(html); Nokogiri::HTML.parse html; end

      let(:generator) { double("URL generator") }
      let(:rewriter) { UrlRewriter.new(generator) }

      it "rewrites all a[href]" do
        generator.should_receive(:generate_url).with("some/path").and_return "http://foo.com/"
        dom = dom_document <<-HTML
          <body>
            <a href="some/path">Some path</a>
          </body>
        HTML

        expect {
          rewriter.transform_dom dom
        }.to change { dom.at_css("a")["href"] }.to "http://foo.com/"
      end

      it "rewrites relative img[src]" do
        generator.should_receive(:generate_url).with("some/path.jpg").and_return "http://foo.com/image.jpg"
        dom = dom_document <<-HTML
          <body>
            <img src="some/path.jpg">
          </body>
        HTML

        expect {
          rewriter.transform_dom dom
        }.to change { dom.at_css("img")["src"] }.to "http://foo.com/image.jpg"
      end
    end
  end
end
