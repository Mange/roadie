require 'spec_helper'

describe Roadie::Inliner do
  def use_css(css); @css = css; end
  def rendering(html, options = {})
    url_options = options.fetch(:url_options, {:host => 'example.com'})
    Nokogiri::HTML.parse Roadie::Inliner.new(@css, html, url_options).execute
  end

  describe "inlining styles" do
    before(:each) do
      # Make sure to have some css even when we don't specify any
      # We have specific tests for when this is nil
      use_css ''
    end

    it "should inline simple attributes" do
      use_css 'p { color: green }'
      rendering('<p></p>').should have_styling('color' => 'green')
    end

    it "should keep the order of the styles that was inlined" do
      use_css 'h1 { padding: 2px; margin: 5px; }'
      rendering('<h1></h1>').should have_styling([['padding', '2px'], ['margin', '5px']])
    end

    it "should combine multiple selectors into one" do
      use_css 'p { color: green; }
              .tip { float: right; }'
      rendering('<p class="tip"></p>').should have_styling('color' => 'green', 'float' => 'right')
    end

    it "should use the ones attributes with the highest specificality when conflicts arises" do
      use_css "p { color: red; }
              .safe { color: green; }"
      rendering('<p class="safe"></p>').should have_styling('color' => 'green')
    end

    it "should sort styles by specificity order" do
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

    it "should support multiple selectors for the same rules" do
      use_css 'p, a { color: green; }'
      rendering('<p></p><a></a>').tap do |document|
        document.should have_styling('color' => 'green').at_selector('p')
        document.should have_styling('color' => 'green').at_selector('a')
      end
    end

    it "should respect !important properties" do
      use_css "a { text-decoration: underline !important; }
               a.hard-to-spot { text-decoration: none; }"
      rendering('<a class="hard-to-spot"></a>').should have_styling('text-decoration' => 'underline')
    end

    it "should combine with already present inline styles" do
      use_css "p { color: green }"
      rendering('<p style="font-size: 1.1em"></p>').should have_styling([['color', 'green'], ['font-size', '1.1em']])
    end

    it "should not touch already present inline styles" do
      use_css "p { color: red }"
      rendering('<p style="color: green"></p>').should have_styling([['color', 'red'], ['color', 'green']])
    end

    it "should ignore selectors with :psuedo-classes" do
      use_css 'p:hover { color: red }'
      rendering('<p></p>').should_not have_styling('color' => 'red')
    end

    describe "inline <style> elements" do
      it "should be used for inlined styles" do
        rendering(<<-HTML).should have_styling([['color', 'green'], ['font-size', '1.1em']])
          <html>
            <head>
              <style type="text/css">p { color: green; }</style>
            </head>
            <body>
              <p>Hello World</p>
              <style type="text/css">p { font-size: 1.1em; }</style>
            </body>
          </html>
        HTML
      end

      it "should be removed" do
        rendering(<<-HTML).should_not have_selector('style')
          <html>
            <head>
              <style type="text/css">p { color: green; }</style>
            </head>
            <body>
              <style type="text/css">p { font-size: 1.1em; }</style>
            </body>
          </html>
        HTML
      end

      it "should not be touched when data-immutable=true" do
        document = rendering <<-HTML
          <style type="text/css" data-immutable="true">p { color: red; }</style>
          <p></p>
        HTML
        document.should have_selector('style[data-immutable=true]')
        document.should_not have_styling('color' => 'red')
      end

      it "should not be touched when media=print" do
        document = rendering <<-HTML
          <style type="text/css" media="print">p { color: red; }</style>
          <p></p>
        HTML
        document.should have_selector('style[media=print]')
        document.should_not have_styling('color' => 'red').at_selector('p')
      end

      it "should still be inlined when no external css rules are defined" do
        use_css nil
        rendering(<<-HTML).should have_styling('color' => 'green').at_selector('p')
          <style type="text/css">p { color: green; }</style>
          <p>Hello World</p>
        HTML
      end
    end
  end

  describe "making urls absolute" do
    it "should work on image sources" do
      rendering('<img src="/images/foo.jpg" />').should have_attribute('src' => 'http://example.com/images/foo.jpg')
      rendering('<img src="../images/foo.jpg" />').should have_attribute('src' => 'http://example.com/images/foo.jpg')
      rendering('<img src="foo.jpg" />').should have_attribute('src' => 'http://example.com/foo.jpg')
    end

    it "should not touch image sources that are already absolute" do
      rendering('<img src="http://other.example.org/images/foo.jpg" />').should have_attribute('src' => 'http://other.example.org/images/foo.jpg')
    end

    it "should work on inlined style attributes" do
      rendering('<p style="background: url(/paper.png)"></p>').should have_styling('background' => 'url(http://example.com/paper.png)')
      rendering('<p style="background: url(&quot;/paper.png&quot;)"></p>').should have_styling('background' => 'url("http://example.com/paper.png")')
    end

    it "should work on external style declarations" do
      use_css "p { background-image: url(/paper.png); }
               table { background-image: url('/paper.png'); }
               div { background-image: url(\"/paper.png\"); }"
      rendering('<p></p>').should have_styling('background-image' => 'url(http://example.com/paper.png)')
      rendering('<table></table>').should have_styling('background-image' => "url('http://example.com/paper.png')")
      rendering('<div></div>').should have_styling('background-image' => 'url("http://example.com/paper.png")')
    end

    it "should not touch style urls that are already absolute" do
      external_url = 'url(http://other.example.org/paper.png)'
      use_css "p { background-image: #{external_url}; }"
      rendering('<p></p>').should have_styling('background-image' => external_url)
      rendering(%(<div style="background-image: #{external_url}"></div>)).should have_styling('background-image' => external_url)
    end

    it "should not touch the urls when no url options are defined" do
      use_css "img { background: url(/a.jpg); }"
      rendering('<img src="/b.jpg" />', :url_options => nil).tap do |document|
        document.should have_attribute('src' => '/b.jpg').at_selector('img')
        document.should have_styling('background' => 'url(/a.jpg)')
      end
    end

    it "should support port and protocol settings" do
      use_css "img { background: url(/a.jpg); }"
      rendering('<img src="/b.jpg" />', :url_options => {:host => 'example.com', :protocol => 'https', :port => '8080'}).tap do |document|
        document.should have_attribute('src' => 'https://example.com:8080/b.jpg').at_selector('img')
        document.should have_styling('background' => 'url(https://example.com:8080/a.jpg)')
      end
    end

    it "should not touch data: URIs" do
      use_css "div { background: url(data:abcdef); }"
      rendering('<div></div>').should have_styling('background' => 'url(data:abcdef)')
    end
  end

  describe "inserting tags" do
    it "should insert a doctype if not present" do
      rendering('<html><body></body></html>').to_xml.should include('<!DOCTYPE ')
      rendering('<!DOCTYPE html><html><body></body></html>').to_xml.should_not match(/(DOCTYPE.*?){2}/)
    end

    it "should set xmlns of <html> to that of XHTML" do
      rendering('<html><body></body></html>').should have_selector('html[xmlns="http://www.w3.org/1999/xhtml"]')
    end

    it "should insert basic html structure if not present" do
      rendering('<h1>Hey!</h1>').should have_selector('html > head + body > h1')
    end

    it "should insert <head> if not present" do
      rendering('<html><body></body></html>').should have_selector('html > head + body')
    end

    it "should insert meta tag describing content-type" do
      rendering('<html><head></head><body></body></html>').should have_selector('head meta[http-equiv="Content-Type"][content="text/html; charset=utf-8"]')
    end

    it "should not insert duplicate meta tags describing content-type" do
      rendering(<<-HTML).to_html.scan('meta').should have(1).item
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
        </head>
      </html>
      HTML
    end
  end

  describe "css url regex" do
    it "should parse css urls" do
      {
        'url(/foo.jpg)' => '/foo.jpg',
        'url("/foo.jpg")' => '/foo.jpg',
        "url('/foo.jpg')" => '/foo.jpg',
        'url(http://localhost/foo.jpg)' => 'http://localhost/foo.jpg',
        'url("http://localhost/foo.jpg")' => 'http://localhost/foo.jpg',
        "url('http://localhost/foo.jpg')" => 'http://localhost/foo.jpg',
        'url(/andromeda_(galaxy).jpg)' => '/andromeda_(galaxy).jpg',
      }.each do |raw, expected|
        raw =~ Roadie::Inliner::CSS_URL_REGEXP
        $2.should == expected
      end
    end
  end
end
