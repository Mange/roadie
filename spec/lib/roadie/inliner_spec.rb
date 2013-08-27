# encoding: UTF-8
require 'spec_helper'

describe Roadie::Inliner do
  before { @css = "" }
  def use_css(css) @css = css end

  def rendering(html, css = @css)
    dom = Nokogiri::HTML.parse html
    Roadie::Inliner.new(dom).inline(css)
    dom
  end

  describe "inlining styles" do
    it "inlines simple attributes" do
      use_css 'p { color: green }'
      rendering('<p></p>').should have_styling('color' => 'green')
    end

    it "inlines browser-prefixed attributes" do
      use_css 'p { -vendor-color: green }'
      rendering('<p></p>').should have_styling('-vendor-color' => 'green')
    end

    it "inlines CSS3 attributes" do
      use_css 'p { border-radius: 2px; }'
      rendering('<p></p>').should have_styling('border-radius' => '2px')
    end

    it "keeps the order of the styles that are inlined" do
      use_css 'h1 { padding: 2px; margin: 5px; }'
      rendering('<h1></h1>').should have_styling([['padding', '2px'], ['margin', '5px']])
    end

    it "combines multiple selectors into one" do
      use_css 'p { color: green; }
              .tip { float: right; }'
      rendering('<p class="tip"></p>').should have_styling([['color', 'green'], ['float', 'right']])
    end

    it "uses the attributes with the highest specificity when conflicts arises" do
      use_css "p { color: red; }
              .safe { color: green; }"
      rendering('<p class="safe"></p>').should have_styling('color' => 'green')
    end

    it "sorts styles by specificity order" do
      use_css 'p      { margin: 2px; }
               #big   { margin: 10px; }
               .down  { margin-bottom: 5px; }'

      rendering('<p class="down"></p>').should have_styling([
        ['margin', '2px'], ['margin-bottom', '5px']
      ])

      rendering('<p class="down" id="big"></p>').should have_styling([
        ['margin-bottom', '5px'], ['margin', '10px']
      ])
    end

    it "supports multiple selectors for the same rules" do
      use_css 'p, a { color: green; }'
      rendering('<p></p><a></a>').tap do |document|
        document.should have_styling('color' => 'green').at_selector('p')
        document.should have_styling('color' => 'green').at_selector('a')
      end
    end

    it "keeps !important properties" do
      use_css "a { text-decoration: underline !important; }
               a.hard-to-spot { text-decoration: none; }"
      rendering('<a class="hard-to-spot"></a>').should have_styling('text-decoration' => 'underline !important')
    end

    it "combines with already present inline styles" do
      use_css "p { color: green }"
      rendering('<p style="font-size: 1.1em"></p>').should have_styling([['color', 'green'], ['font-size', '1.1em']])
    end

    it "does not touch already present inline styles" do
      use_css "p { color: red }"
      rendering('<p style="color: green"></p>').should have_styling([['color', 'red'], ['color', 'green']])
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
      rendering('<p class="active"></p>').should have_styling('width' => '100%')
    end

    it "does not crash on any pseudo element selectors" do
      use_css "
        p.some-element { width: 100%; }
        p::some-element { color: red; }
      "
      rendering('<p class="some-element"></p>').should have_styling('width' => '100%')
    end

    it "works with nth-child" do
      use_css "
        p { color: red; }
        p:nth-child(2n) { color: green; }
      "
      rendering("
        <p class='one'></p>
        <p class='two'></p>
      ").should have_styling('color' => 'green').at_selector('.two')
    end

    it "ignores selectors with @" do
      use_css '@keyframes progress-bar-stripes {
        from {
          background-position: 40px 0;
        }
        to {
          background-position: 0 0;
        }
      }'
      expect { rendering('<p></p>') }.not_to raise_error
    end

    it 'ignores HTML comments and CDATA sections' do
      # TinyMCE posts invalid CSS. We support that just to be pragmatic.
      use_css %(<![CDATA[
        <!--
        p { color: green }
        -->
      ]]>)
      expect { rendering '<p></p>' }.not_to raise_error

      use_css %(
        <!--
        <![CDATA[
            <![CDATA[
        span { color: red }
        ]]>
        -->
      )
      expect { rendering '<p></p>' }.not_to raise_error
    end

    it "does not pick up scripts generating styles" do
      expect {
        rendering <<-HTML
          <script>
            var color = "red";
            document.write("<style type='text/css'>p { color: " + color + "; }</style>");
          </script>
        HTML
      }.not_to raise_error
    end
  end

  describe "inserting tags" do
    it "inserts a doctype if not present" do
      rendering('<html><body></body></html>').to_xml.should include('<!DOCTYPE ')
      rendering('<!DOCTYPE html><html><body></body></html>').to_xml.should_not match(/(DOCTYPE.*?){2}/)
    end

    it "sets xmlns of <html> to that of XHTML" do
      rendering('<html><body></body></html>').should have_node('html').with_attributes("xmlns" => "http://www.w3.org/1999/xhtml")
    end

    it "inserts basic html structure if not present" do
      rendering('<h1>Hey!</h1>').should have_selector('html > head + body > h1')
    end

    it "inserts <head> if not present" do
      rendering('<html><body></body></html>').should have_selector('html > head + body')
    end

    it "inserts meta tag describing content-type" do
      rendering('<html><head></head><body></body></html>').tap do |document|
        document.should have_selector('head meta[http-equiv="Content-Type"]')
        document.css('head meta[http-equiv="Content-Type"]').first['content'].should == 'text/html; charset=UTF-8'
      end
    end

    it "does not insert duplicate meta tags describing content-type" do
      rendering(<<-HTML).to_html.scan('meta').should have(1).item
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
        </head>
      </html>
      HTML
    end
  end
end
