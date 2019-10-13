# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/url_rewriter'

module Roadie
  describe UrlRewriter do
    let(:generator) { double("URL generator") }
    subject(:rewriter) { UrlRewriter.new(generator) }

    it_behaves_like "url rewriter"

    describe "transforming DOM trees" do
      def dom_document(html); Nokogiri::HTML.parse html; end

      it "rewrites all a[href]" do
        expect(generator).to receive(:generate_url).with("some/path").and_return "http://foo.com/"
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
        expect(generator).to receive(:generate_url).with("some/path.jpg").and_return "http://foo.com/image.jpg"
        dom = dom_document <<-HTML
          <body>
            <img src="some/path.jpg">
          </body>
        HTML

        expect {
          rewriter.transform_dom dom
        }.to change { dom.at_css("img")["src"] }.to "http://foo.com/image.jpg"
      end

      it "rewrites url() directives inside style attributes" do
        expect(generator).to receive(:generate_url).with("some/path.jpg").and_return "http://foo.com/image.jpg"
        dom = dom_document <<-HTML
          <body>
            <div style="background-image: url(&quot;some/path.jpg&quot;);">
          </body>
        HTML

        expect {
          rewriter.transform_dom dom
        }.to change { dom.at_css("div")["style"] }.to 'background-image: url("http://foo.com/image.jpg");'
      end

      it "skips elements with data-roadie-ignore attributes" do
        allow(generator).to receive(:generate_url).and_return("http://example.com")

        dom = dom_document <<-HTML
          <body>
            <a href="some/path.jpg" data-roadie-ignore>Image</a>
            <img src="some/path.jpg" data-roadie-ignore>
            <div style="background-image: url(&quot;some/path.jpg&quot;);" data-roadie-ignore>
          </body>
        HTML

        rewriter.transform_dom dom

        expect(generator).not_to have_received(:generate_url)
      end
    end

    describe "transforming css" do
      it "rewrites all url() directives" do
        expect(generator).to receive(:generate_url).with("some/path.jpg").and_return "http://foo.com/image.jpg"
        css = "body { background: top url(some/path.jpg) #eee; }"
        transformed_css = rewriter.transform_css css
        expect(transformed_css).to eq "body { background: top url(http://foo.com/image.jpg) #eee; }"
      end

      it "correctly identifies URLs with single quotes" do
        expect(generator).to receive(:generate_url).with("images/foo.png").and_return "x"
        rewriter.transform_css "url('images/foo.png')"
      end

      it "correctly identifies URLs with double quotes" do
        expect(generator).to receive(:generate_url).with("images/foo.png").and_return "x"
        rewriter.transform_css 'url("images/foo.png")'
      end

      it "correctly identifies URLs with parenthesis inside them" do
        expect(generator).to receive(:generate_url).with("images/map_(large_(extra)).png").and_return "x"
        rewriter.transform_css 'url(images/map_(large_(extra)).png)'
      end
    end
  end
end
