# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe Inliner do
    before { @stylesheet = "".freeze }
    def use_css(css) @stylesheet = Stylesheet.new("example", css) end

    def rendering(html, stylesheet = @stylesheet)
      dom = Nokogiri::HTML.parse html
      Inliner.new([stylesheet], dom).inline
      dom
    end

    describe "inlining styles" do
      it "inlines simple attributes" do
        use_css 'p { color: green }'
        expect(rendering('<p></p>')).to have_styling('color' => 'green')
      end

      it "keeps multiple versions of the same property to support progressive enhancement" do
        # https://github.com/premailer/css_parser/issues/44
        pending "css_parser issue #44"

        use_css 'p { color: #eee; color: rgba(255, 255, 255, 0.9); }'
        expect(rendering('<p></p>')).to have_styling(
          [['color', 'green'], ['color', 'rgba(255, 255, 255, 0.9)']]
        )
      end

      it "de-duplicates identical styles" do
        use_css '
          p { color: green; }
          .message { color: blue; }
          .positive { color: green; }
        '
        expect(rendering('<p class="message positive"></p>')).to have_styling(
          [['color', 'blue'], ['color', 'green']]
        )
      end

      it "inlines browser-prefixed attributes" do
        use_css 'p { -vendor-color: green }'
        expect(rendering('<p></p>')).to have_styling('-vendor-color' => 'green')
      end

      it "inlines CSS3 attributes" do
        use_css 'p { border-radius: 2px; }'
        expect(rendering('<p></p>')).to have_styling('border-radius' => '2px')
      end

      it "keeps the order of the styles that are inlined" do
        use_css 'h1 { padding: 2px; margin: 5px; }'
        expect(rendering('<h1></h1>')).to have_styling([['padding', '2px'], ['margin', '5px']])
      end

      it "combines multiple selectors into one" do
        use_css 'p { color: green; }
                .tip { float: right; }'
        expect(rendering('<p class="tip"></p>')).to have_styling([['color', 'green'], ['float', 'right']])
      end

      it "uses the attributes with the highest specificity when conflicts arises" do
        use_css ".safe { color: green; }
                p { color: red; }"
        expect(rendering('<p class="safe"></p>')).to have_styling([['color', 'red'], ['color', 'green']])
      end

      it "sorts styles by specificity order" do
        use_css 'p          { important: no; }
                 #important { important: very; }
                 .important { important: yes; }'

        expect(rendering('<p class="important"></p>')).to have_styling([
          %w[important no], %w[important yes]
        ])

        expect(rendering('<p class="important" id="important"></p>')).to have_styling([
          %w[important no], %w[important yes], %w[important very]
        ])
      end

      it "supports multiple selectors for the same rules" do
        use_css 'p, a { color: green; }'
        rendering('<p></p><a></a>').tap do |document|
          expect(document).to have_styling('color' => 'green').at_selector('p')
          expect(document).to have_styling('color' => 'green').at_selector('a')
        end
      end

      it "keeps !important properties" do
        use_css "a { text-decoration: underline !important; }
                 a.hard-to-spot { text-decoration: none; }"
        expect(rendering('<a class="hard-to-spot"></a>')).to have_styling([
          ['text-decoration', 'none'], ['text-decoration', 'underline !important']
        ])
      end

      it "combines with already present inline styles" do
        use_css "p { color: green }"
        expect(rendering('<p style="font-size: 1.1em"></p>')).to have_styling([['color', 'green'], ['font-size', '1.1em']])
      end

      it "does not override inline styles" do
        use_css "p { text-transform: uppercase; color: red }"
        # The two color properties are kept to make css fallbacks work correctly
        expect(rendering('<p style="color: green"></p>')).to have_styling([
          ['text-transform', 'uppercase'],
          ['color', 'red'],
          ['color', 'green'],
        ])
      end

      it "does not apply link and dynamic pseudo selectors" do
        use_css "
          p:active { color: red }
          p:focus { color: red }
          p:hover { color: red }
          p:link { color: red }
          p:target { color: red }
          p:visited { color: red }

          p.active { width: 100%; }
        "
        expect(rendering('<p class="active"></p>')).to have_styling('width' => '100%')
      end

      it "does not crash on any pseudo element selectors" do
        use_css "
          p.some-element { width: 100%; }
          p::some-element { color: red; }
        "
        expect(rendering('<p class="some-element"></p>')).to have_styling('width' => '100%')
      end

      it "warns on selectors that crash Nokogiri" do
        dom = Nokogiri::HTML.parse "<p></p>"

        stylesheet = Stylesheet.new "foo.css", "p[%^=foo] { color: red; }"
        inliner = Inliner.new([stylesheet], dom)
        expect(Utils).to receive(:warn).with(
          %{Cannot inline "p[%^=foo]" from "foo.css" stylesheet. If this is valid CSS, please report a bug.}
        )
        inliner.inline
      end

      it "works with nth-child" do
        use_css "
          p { color: red; }
          p:nth-child(2n) { color: green; }
        "
        result = rendering("<p></p> <p></p>")

        expect(result).to have_styling([['color', 'red']]).at_selector('p:first')
        expect(result).to have_styling([['color', 'red'], ['color', 'green']]).at_selector('p:last')
      end

      context "with uninlinable selectors" do
        before do
          allow(Roadie::Utils).to receive(:warn)
        end

        it "puts them in a new <style> element in the <head>" do
          use_css 'a:hover { color: red; }'
          result = rendering("
            <html>
              <head></head>
              <body><a></a></body>
            </html>
          ")
          expect(result).to have_selector("head > style")
          expect(result.at_css("head > style").text).to eq "a:hover{color:red}"
        end

        it "puts them in <head> on unexpected inlining problems" do
          use_css 'p:some-future-thing { color: red; }'
          result = rendering("
            <html>
              <head></head>
              <body><p></p></body>
            </html>
          ")
          expect(result).to have_selector("head > style")
          expect(result.at_css("head > style").text).to eq "p:some-future-thing{color:red}"
        end

        # This is not really wanted behavior, but there's nothing we can do
        # about it because of limitations on CSS Parser.
        it "puts does not put keyframes in <head>" do
          css = '@keyframes progress-bar-stripes {
            from {
              background-position: 40px 0;
            }
            to {
              background-position: 0 0;
            }
          }'

          use_css css
          result = rendering('<p></p>')

          expect(result).to have_styling([]).at_selector("p")

          # css_parser actually sees an empty @keyframes on JRuby, and nothing
          # on the others
          if (style_element = result.at_css("head > style"))
            expect(style_element.text).to_not include "background-position"
          end
        end

        it "ignores them if told not to keep them" do
          stylesheet = use_css "
            p:hover { color: red; }
            p:some-future-thing { color: red; }
          "
          dom = Nokogiri::HTML.parse "
            <html>
              <head></head>
              <body><p></p></body>
            </html>
          "
          Inliner.new([stylesheet], dom).inline(false)
          expect(dom).to_not have_selector("head > style")
        end
      end
    end
  end
end
