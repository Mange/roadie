require 'spec_helper'

describe "Roadie functionality" do
  def parse_html(html)
    Nokogiri::HTML.parse(html)
  end

  it "adds missing structure" do
    html = "<h1>Hello world!</h1>".encode("Shift_JIS")
    document = Roadie::Document.new(html)
    result = document.transform

    unless defined?(JRuby)
      # JRuby has a bug that makes DTD manipulation impossible
      # See Nokogiri bugs #984 and #985
      # https://github.com/sparklemotion/nokogiri/issues/984
      # https://github.com/sparklemotion/nokogiri/issues/985
      result.should include("<!DOCTYPE html>")
    end

    result.should include("<html>")
    result.should include("<head>")
    result.should include("<body>")

    result.should include("<meta")
    result.should include("text/html; charset=Shift_JIS")
  end

  it "inlines given css" do
    document = Roadie::Document.new <<-HTML
      <html>
        <head>
          <title>Hello world!</title>
        </head>
        <body>
          <h1>Hello world!</h1>
          <p>Check out these <em>awesome</em> prices!</p>
        </body>
      </html>
    HTML
    document.add_css <<-CSS
      em { color: red; }
      h1 { text-align: center; }
    CSS

    result = parse_html document.transform
    result.should have_styling('text-align' => 'center').at_selector('h1')
    result.should have_styling('color' => 'red').at_selector('p > em')
  end

  it "inlines css from disk" do
    document = Roadie::Document.new <<-HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>Hello world!</title>
          <link rel="stylesheet" href="/spec/fixtures/big_em.css">
        </head>
        <body>
          <h1>Hello world!</h1>
          <p>Check out these <em>awesome</em> prices!</p>
        </body>
      </html>
    HTML

    result = parse_html document.transform
    result.should have_styling('font-size' => '200%').at_selector('p > em')
  end

  it "crashes when stylesheets cannot be found, unless using NullProvider" do
    document = Roadie::Document.new <<-HTML
      <!DOCTYPE html>
      <html>
        <head>
          <link rel="stylesheet" href="/spec/fixtures/does_not_exist.css">
        </head>
        <body>
        </body>
      </html>
    HTML

    expect { document.transform }.to raise_error(Roadie::CssNotFound, /does_not_exist\.css/)

    document.asset_providers << Roadie::NullProvider.new
    expect { document.transform }.to_not raise_error
  end

  it "makes URLs absolute" do
    document = Roadie::Document.new <<-HTML
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { background: url("/assets/bg-abcdef1234567890.png"); }
          </style>
          <link rel="stylesheet" href="/style.css">
        </head>
        <body>
          <a href="/about_us"><img src="/assets/about_us-abcdef1234567890.png" alt="About us"></a>
        </body>
      </html>
    HTML

    document.asset_providers = TestProvider.new(
      "/style.css" => "a { background: url(/assets/link-abcdef1234567890.png); }"
    )
    document.url_options = {host: "myapp.com", scheme: "https", path: "rails/app/"}
    result = parse_html document.transform

    result.at_css("a")["href"].should == "https://myapp.com/rails/app/about_us"

    result.at_css("img")["src"].should == "https://myapp.com/rails/app/assets/about_us-abcdef1234567890.png"

    result.should have_styling(
      "background" => 'url("https://myapp.com/rails/app/assets/bg-abcdef1234567890.png")'
    ).at_selector("body")

    result.should have_styling(
      "background" => 'url(https://myapp.com/rails/app/assets/link-abcdef1234567890.png)'
    ).at_selector("a")
  end

  it "allows custom callbacks during inlining" do
    document = Roadie::Document.new <<-HTML
      <!DOCTYPE html>
      <html>
        <body>
          <span>Hello world</span>
        </body>
      </html>
    HTML

    document.before_transformation = proc { |dom| dom.at_css("body")["class"] = "roadie" }
    document.after_transformation = proc { |dom| dom.at_css("span").remove }

    result = parse_html document.transform
    result.at_css("body")["class"].should == "roadie"
    result.at_css("span").should be_nil
  end
end
