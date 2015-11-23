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
      expect(result).to include("<!DOCTYPE html>")
    end

    expect(result).to include("<html>")
    expect(result).to include("<head>")
    expect(result).to include("<body>")

    expect(result).to include("<meta")
    expect(result).to include("text/html; charset=Shift_JIS")
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
    expect(result).to have_styling('text-align' => 'center').at_selector('h1')
    expect(result).to have_styling('color' => 'red').at_selector('p > em')
  end

  it "stores styles that cannot be inlined in the <head>" do
    document = Roadie::Document.new <<-HTML
      <html>
        <body>
          <h1>Hello world!</h1>
          <p>Check out these <em>awesome</em> prices!</p>
        </body>
      </html>
    HTML
    css = <<-CSS
      em:hover { color: red; }
      p:fung-shuei { color: spirit; }
    CSS
    document.add_css css
    expect(Roadie::Utils).to receive(:warn).with(/fung-shuei/)

    result = parse_html document.transform
    expect(result).to have_selector("html > head > style")

    styles = result.at_css("html > head > style").text
    expect(styles).to include Roadie::Stylesheet.new("", css).to_s
  end

  it "can be configured to skip styles that cannot be inlined" do
    document = Roadie::Document.new <<-HTML
      <html>
        <body>
          <h1>Hello world!</h1>
          <p>Check out these <em>awesome</em> prices!</p>
        </body>
      </html>
    HTML
    css = <<-CSS
      em:hover { color: red; }
      p:fung-shuei { color: spirit; }
    CSS
    document.add_css css
    document.keep_uninlinable_css = false

    expect(Roadie::Utils).to receive(:warn).with(/fung-shuei/)

    result = parse_html document.transform
    expect(result).to_not have_selector("html > head > style")
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
    expect(result).to have_styling('font-size' => '200%').at_selector('p > em')
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

  it "ignores external css if no external providers are added" do
    document = Roadie::Document.new <<-HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>Hello world!</title>
          <link rel="stylesheet" href="http://example.com/big_em.css">
        </head>
        <body>
          <h1>Hello world!</h1>
          <p>Check out these <em>awesome</em> prices!</p>
        </body>
      </html>
    HTML

    document.external_asset_providers = []

    result = parse_html document.transform
    expect(result).to have_selector('head > link')
    expect(result).to have_styling([]).at_selector('p > em')
  end

  it "inlines external css if configured" do
    document = Roadie::Document.new <<-HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>Hello world!</title>
          <link rel="stylesheet" href="http://example.com/big_em.css">
        </head>
        <body>
          <h1>Hello world!</h1>
          <p>Check out these <em>awesome</em> prices!</p>
        </body>
      </html>
    HTML

    document.external_asset_providers = TestProvider.new(
      "http://example.com/big_em.css" => "em { font-size: 200%; }"
    )

    result = parse_html document.transform
    expect(result).to have_styling('font-size' => '200%').at_selector('p > em')
    expect(result).to_not have_selector('head > link')
  end

  it "does not inline the same properties several times" do
    document = Roadie::Document.new <<-HTML
      <head>
        <link rel="stylesheet" href="hello.css">
      </head>
      <body>
        <p class="hello world">Hello world</p>
      </body>
    HTML

    document.asset_providers = TestProvider.new("hello.css" => <<-CSS)
      p { color: red; }
      .hello { color: red; }
      .world { color: red; }
    CSS

    result = parse_html document.transform
    expect(result).to have_styling([
      ['color', 'red']
    ]).at_selector('p')
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

    expect(result.at_css("a")["href"]).to eq("https://myapp.com/rails/app/about_us")

    expect(result.at_css("img")["src"]).to eq("https://myapp.com/rails/app/assets/about_us-abcdef1234567890.png")

    expect(result).to have_styling(
      "background" => 'url("https://myapp.com/rails/app/assets/bg-abcdef1234567890.png")'
    ).at_selector("body")

    expect(result).to have_styling(
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
    expect(result.at_css("body")["class"]).to eq("roadie")
    expect(result.at_css("span")).to be_nil
  end
end
