# encoding: UTF-8
require 'spec_helper'

describe Roadie::Inliner do
  before { @css = "" }
  def use_css(css) @css = css end

  def rendering(html, css = @css)
    dom = Nokogiri::HTML.parse html
    Roadie::Inliner.new(css).inline(dom)
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

    it "does not override inline styles" do
      use_css "p { text-transform: uppercase; color: red }"
      # TODO: Remove the duplicate properties
      rendering('<p style="color: green"></p>').should have_styling([
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
  end
end
