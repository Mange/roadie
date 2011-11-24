# encoding: UTF-8
require 'spec_helper'

describe Roadie::Inliner do
  let(:provider) { double("asset provider", :all => '') }

  def use_css(css)
    provider.stub(:all).with(['global.css']).and_return(css)
  end

  def rendering(html, options = {})
    url_options = options.fetch(:url_options, {:host => 'example.com'})
    Nokogiri::HTML.parse Roadie::Inliner.new(provider, ['global.css'], html, url_options).execute
  end

  describe "initialization" do
    it "warns about asset_path_prefix being non-functional" do
      expect {
        Roadie::Inliner.new(provider, [], '', :asset_path_prefix => 'foo')
      }.to raise_error(ArgumentError, /asset_path_prefix/)
    end
  end

  describe "inlining styles" do
    before(:each) do
      # Make sure to have some css even when we don't specify any
      # We have specific tests for when this is nil
      use_css ''
    end

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
      rendering('<p class="tip"></p>').should have_styling('color' => 'green', 'float' => 'right')
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

    it "respects !important properties" do
      use_css "a { text-decoration: underline !important; }
               a.hard-to-spot { text-decoration: none; }"
      rendering('<a class="hard-to-spot"></a>').should have_styling('text-decoration' => 'underline')
    end

    it "combines with already present inline styles" do
      use_css "p { color: green }"
      rendering('<p style="font-size: 1.1em"></p>').should have_styling([['color', 'green'], ['font-size', '1.1em']])
    end

    it "does not touch already present inline styles" do
      use_css "p { color: red }"
      rendering('<p style="color: green"></p>').should have_styling([['color', 'red'], ['color', 'green']])
    end

    it "ignores selectors with :psuedo-classes" do
      use_css 'p:hover { color: red }'
      rendering('<p></p>').should_not have_styling('color' => 'red')
    end

    describe "inline <style> element" do
      it "is used for inlined styles" do
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

      it "is removed" do
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

      it "is not touched when data-immutable is set" do
        document = rendering <<-HTML
          <style type="text/css" data-immutable>p { color: red; }</style>
          <p></p>
        HTML
        document.should have_selector('style[data-immutable]')
        document.should_not have_styling('color' => 'red')
      end

      it "is not touched when for print media" do
        document = rendering <<-HTML
          <style type="text/css" media="print">p { color: red; }</style>
          <p></p>
        HTML
        document.should have_selector('style[media=print]')
        document.should_not have_styling('color' => 'red').at_selector('p')
      end

      it "is still inlined when no external css rules are defined" do
        # This is just testing that the main code paths are still active even
        # when css is set to nil
        use_css nil
        rendering(<<-HTML).should have_styling('color' => 'green').at_selector('p')
          <style type="text/css">p { color: green; }</style>
          <p>Hello World</p>
        HTML
      end
    end
  end

  describe "linked stylesheets" do
    def fake_file(name, contents)
      provider.should_receive(:find).with(name).and_return(contents)
    end

    it "inlines styles from the linked stylesheet" do
      fake_file('/assets/green_paragraphs.css', 'p { color: green; }')

      rendering(<<-HTML).should have_styling('color' => 'green').at_selector('p')
        <html>
          <head>
            <link rel="stylesheet" href="/assets/green_paragraphs.css">
          </head>
          <body>
            <p></p>
          </body>
        </html>
      HTML
    end

    it "inlines styles from the linked stylesheet in subdirectory" do
      fake_file('/assets/subdirectory/red_paragraphs.css', 'p { color: red; }')

      rendering(<<-HTML).should have_styling('color' => 'red').at_selector('p')
        <html>
          <head>
            <link rel="stylesheet" href="/assets/subdirectory/red_paragraphs.css">
          </head>
          <body>
            <p></p>
          </body>
        </html>
      HTML
    end

    it "inlines styles from more than one linked stylesheet" do
      fake_file('/assets/large_purple_paragraphs.css', 'p { font-size: 18px; color: purple; }')
      fake_file('/assets/green_paragraphs.css', 'p { color: green; }')

      html = <<-HTML
        <html>
          <head>
            <link rel="stylesheet" href="/assets/large_purple_paragraphs.css">
            <link rel="stylesheet" href="/assets/green_paragraphs.css">
          </head>
          <body>
            <p></p>
          </body>
        </html>
      HTML

      rendering(html).should have_styling([
        ['font-size', '18px'],
        ['color', 'green'],
      ]).at_selector('p')
    end

    it "removes the stylesheet links from the DOM" do
      provider.stub(:find => '')
      rendering(<<-HTML).should_not have_selector('link')
        <html>
          <head>
            <link rel="stylesheet" href="/assets/green_paragraphs.css">
            <link rel="stylesheet" href="/assets/large_purple_paragraphs.css">
          </head>
          <body>
          </body>
        </html>
      HTML
    end

    context "when stylesheet is for print media" do
      it "does not inline the stylesheet" do
        rendering(<<-HTML).should_not have_styling('color' => 'green').at_selector('p')
          <html>
            <head>
              <link rel="stylesheet" href="/assets/green_paragraphs.css" media="print">
            </head>
            <body>
              <p></p>
            </body>
          </html>
        HTML
      end

      it "does not remove the links" do
        rendering(<<-HTML).should have_selector('link')
          <html>
            <head>
              <link rel="stylesheet" href="/assets/green_paragraphs.css" media="print">
            </head>
            <body>
            </body>
          </html>
        HTML
      end
    end

    context "when stylesheet is marked as immutable" do
      it "does not inline the stylesheet" do
        rendering(<<-HTML).should_not have_styling('color' => 'green').at_selector('p')
          <html>
            <head>
              <link rel="stylesheet" href="/assets/green_paragraphs.css" data-immutable="true">
            </head>
            <body>
              <p></p>
            </body>
          </html>
        HTML
      end

      it "does not remove link" do
        rendering(<<-HTML).should have_selector('link')
          <html>
            <head>
              <link rel="stylesheet" href="/assets/green_paragraphs.css" data-immutable="true">
            </head>
            <body>
            </body>
          </html>
        HTML
      end
    end

    context "when stylesheet link uses an absolute URL" do
      it "does not inline the stylesheet" do
        rendering(<<-HTML).should_not have_styling('color' => 'green').at_selector('p')
          <html>
            <head>
              <link rel="stylesheet" href="http://www.example.com/green_paragraphs.css">
            </head>
            <body>
              <p></p>
            </body>
          </html>
        HTML
      end

      it "does not remove link" do
        rendering(<<-HTML).should have_selector('link')
          <html>
            <head>
              <link rel="stylesheet" href="http://www.example.com/green_paragraphs.css">
            </head>
            <body>
            </body>
          </html>
        HTML
      end
    end

    context "stylesheet cannot be found on disk" do
      it "raises an error" do
        html = <<-HTML
          <html>
            <head>
              <link rel="stylesheet" href="/assets/not_found.css">
            </head>
            <body>
            </body>
          </html>
        HTML

        expect { rendering(html) }.to raise_error do |error|
          error.should be_a(Roadie::CSSFileNotFound)
          error.filename.should == Roadie.app.assets['not_found.css']
          error.guess.should == '/assets/not_found.css'
        end
      end
    end

    context "link element is not for a stylesheet" do
      it "is ignored" do
        html = <<-HTML
          <html>
            <head>
              <link rel="not_stylesheet" href="/assets/green_paragraphs.css">
            </head>
            <body>
              <p></p>
            </body>
          </html>
        HTML
        rendering(html).tap do |document|
          document.should_not have_styling('color' => 'green').at_selector('p')
          document.should have_selector('link')
        end
      end
    end
  end

  describe "making urls absolute" do
    it "works on image sources" do
      rendering('<img src="/images/foo.jpg" />').should have_attribute('src' => 'http://example.com/images/foo.jpg')
      rendering('<img src="../images/foo.jpg" />').should have_attribute('src' => 'http://example.com/images/foo.jpg')
      rendering('<img src="foo.jpg" />').should have_attribute('src' => 'http://example.com/foo.jpg')
    end

    it "does not touch image sources that are already absolute" do
      rendering('<img src="http://other.example.org/images/foo.jpg" />').should have_attribute('src' => 'http://other.example.org/images/foo.jpg')
    end

    it "works on inlined style attributes" do
      rendering('<p style="background: url(/paper.png)"></p>').should have_styling('background' => 'url(http://example.com/paper.png)')
      rendering('<p style="background: url(&quot;/paper.png&quot;)"></p>').should have_styling('background' => 'url("http://example.com/paper.png")')
    end

    it "works on external style declarations" do
      use_css "p { background-image: url(/paper.png); }
               table { background-image: url('/paper.png'); }
               div { background-image: url(\"/paper.png\"); }"
      rendering('<p></p>').should have_styling('background-image' => 'url(http://example.com/paper.png)')
      rendering('<table></table>').should have_styling('background-image' => "url('http://example.com/paper.png')")
      rendering('<div></div>').should have_styling('background-image' => 'url("http://example.com/paper.png")')
    end

    it "does not touch style urls that are already absolute" do
      external_url = 'url(http://other.example.org/paper.png)'
      use_css "p { background-image: #{external_url}; }"
      rendering('<p></p>').should have_styling('background-image' => external_url)
      rendering(%(<div style="background-image: #{external_url}"></div>)).should have_styling('background-image' => external_url)
    end

    it "does not touch the urls when no url options are defined" do
      use_css "img { background: url(/a.jpg); }"
      rendering('<img src="/b.jpg" />', :url_options => nil).tap do |document|
        document.should have_attribute('src' => '/b.jpg').at_selector('img')
        document.should have_styling('background' => 'url(/a.jpg)')
      end
    end

    it "supports port and protocol settings" do
      use_css "img { background: url(/a.jpg); }"
      rendering('<img src="/b.jpg" />', :url_options => {:host => 'example.com', :protocol => 'https', :port => '8080'}).tap do |document|
        document.should have_attribute('src' => 'https://example.com:8080/b.jpg').at_selector('img')
        document.should have_styling('background' => 'url(https://example.com:8080/a.jpg)')
      end
    end

    it "does not touch data: URIs" do
      use_css "div { background: url(data:abcdef); }"
      rendering('<div></div>').should have_styling('background' => 'url(data:abcdef)')
    end
  end

  describe "inserting tags" do
    it "inserts a doctype if not present" do
      rendering('<html><body></body></html>').to_xml.should include('<!DOCTYPE ')
      rendering('<!DOCTYPE html><html><body></body></html>').to_xml.should_not match(/(DOCTYPE.*?){2}/)
    end

    it "sets xmlns of <html> to that of XHTML" do
      rendering('<html><body></body></html>').should have_selector('html[xmlns="http://www.w3.org/1999/xhtml"]')
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

  describe "css url regex" do
    it "parses css urls" do
      {
        %{url(/foo.jpg)}                   => '/foo.jpg',
        %{url("/foo.jpg")}                 => '/foo.jpg',
        %{url('/foo.jpg')}                 => '/foo.jpg',
        %{url(http://localhost/foo.jpg)}   => 'http://localhost/foo.jpg',
        %{url("http://localhost/foo.jpg")} => 'http://localhost/foo.jpg',
        %{url('http://localhost/foo.jpg')} => 'http://localhost/foo.jpg',
        %{url(/andromeda_(galaxy).jpg)}    => '/andromeda_(galaxy).jpg',
      }.each do |raw, expected|
        raw =~ Roadie::Inliner::CSS_URL_REGEXP
        $2.should == expected
      end
    end
  end
end
