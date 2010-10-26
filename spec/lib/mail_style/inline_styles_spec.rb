# coding: utf-8
require 'spec_helper'

# Set ActionMailer stuff
ActionMailer::Base.prepend_view_path '.'
ActionMailer::Base.deliveries = []

# Test Mailer
class TestMailer < ActionMailer::Base
  default :from => "john@example.com", :to => "doe@example.com", :css => :simple

  def multipart(css_file = nil)
    mail(:subject => "Multipart email") do |format|
      format.html { render :text => '<p class="text">Hello <a href="htt://example.com/">World</a></p>' }
      format.text { render :text => 'Hello World' }
    end
  end

  # Not sure how to implement this one.
  # TODO: Either remove or implement
  def nested_multipart_mixed(css_file = nil)
    raise "Nested multipart mixed is not implemented"
    content_type "multipart/mixed"
    part :content_type => "multipart/alternative", :content_disposition => "inline" do |p|
      p.part :content_type => 'text/html', :body => '<p class="text">Hello World</p>'
      p.part :content_type => 'text/plain', :body => 'Hello World'
    end
  end

  def inline_rules(rules)
    mail(:subject => "Inline rules email") do |format|
      format.html { render :text => %(#{rules}<p class="text">Hello World</p>)}
      format.text { render :text => 'Hello World' }
    end
  end

  def singlepart_html
    mail(:subject => "HTML email") do |format|
      format.html { render :text => '<p class="text">Hello World</p>' }
    end
  end

  def singlepart_plain
    mail(:subject => "Text email") do |format|
      # NOTE: Rendering html in plain text
      format.text { render :text => '<p class="text">Hello World</p>' }
    end
  end

  def image_urls(css_file = nil)
    mail(:subject => "Image URLs email") do |format|
      format.html { render :text => '<p id="image">Hello World</p><p id="image2">Goodbye World</p><img src="/images/test.jpg" />' }
      format.text { render :text => 'Hello World' }
    end
  end
end

TestMailer.configure do |config|
  config.default_url_options = {:host => "example.com"}
  config.perform_deliveries = true
  config.delivery_method = :test
end

shared_examples_for "inline styles" do
  before(:each) do
    css_rules <<-EOF
      body { background: #000 }
      .text { color: #0f0; font-size: 14px }
      p { color: #f00; line-height: 1.5 }
    EOF
  end

  it "should add the correct xml namespace" do
    should match(/<html xmlns="http:\/\/www\.w3\.org\/1999\/xhtml">/)
  end

  it "should write the xhtml 1.0 doctype" do
    should match(/<!DOCTYPE html PUBLIC "-\/\/W3C\/\/DTD XHTML 1\.0 Transitional\/\/EN" "http:\/\/www.w3.org\/TR\/xhtml1\/DTD\/xhtml1-transitional\.dtd">/mi)
  end

  it "should write utf-8 content type meta tag" do
    should match(/<head>.*<meta http\-equiv="Content\-Type" content="text\/html; charset=utf\-8">.*<\/head>/mi)
  end

  it "should wrap with html and body tag if missing" do
    should match(/<html.*>.*<body.*>.*<\/body>.*<\/html>/m)
  end

  it "should add style to body" do
    should match(/<body style="background: #000">/)
  end

  it "should add both styles to paragraph" do
    should match(/<p class="text" style="color: #0f0;font-size: 14px;line-height: 1.5">/)
  end

  it "should not crash on :pseudo-classes" do
    css_rules("a:link { color: #f00 }")
    expect do
      subject
    end.to_not raise_error(StandardError)
  end
end

describe MailStyle::InlineStyles do
  let(:text_body) { email.parts.select { |part| part.mime_type == 'text/plain' }.body.to_s }
  let(:html_body) { email.parts.select { |part| part.mime_type == 'text/html' }.body.to_s }
  let(:body) { email.body.to_s }

  use_css 'simple', <<-CSS
    body { background: #000 }
    p { color: #f00; line-height: 1.5 }
    .text { font-size: 14px }
  CSS

  describe 'singlepart' do
    describe "text/html" do
      let(:email) { TestMailer.singlepart_html }

      it "should have styles applied" do
        body.should include('color: #f00')
      end
    end

    describe "text/plain" do
      let(:email) { TestMailer.singlepart_plain }

      it "should not be changed" do
        body.should eql('<p class="text">Hello World</p>')
      end
    end
  end

  describe 'multipart' do
    before(:each) { pending }

    describe 'image urls' do
      before(:each) do
        # CSS rules
        css_rules <<-EOF
          p#image { background: url(../images/test-image.png) }
          p#image2 { background: url("../images/test-image.png") }
        EOF

        # Generate email
        @email = TestMailer.deliver_test_image_urls(:real)
        @html = html_part(@email)
      end

      it "should make the css urls absolute" do
        @html.should match(/<p.*style="background: url\(http:\/\/example\.com\/images\/test\-image\.png\)">/)
      end

      it "should not be greedy with the image url match" do
        @html.should match(/<p id="image2" style='background: url\("http:\/\/example\.com\/images\/test\-image\.png"\)'>/)
      end

      it "should make image sources absolute" do
        # Note: Nokogiri loses the closing slash from the <img> tag for some reason.
        @html.should match(/<img src="http:\/\/example\.com\/images\/test\.jpg\">/)
      end
    end

    describe 'rendering inline styles' do
      let(:email) { TestMailer.deliver_test_multipart(:real) }
      subject     { html_part(email) }
      it_should_behave_like("inline styles")
    end

    describe 'combining styles' do
      it "should select the most specific style" do
        css_rules <<-EOF
          .text { color: #0f0; }
          p { color: #f00; }
        EOF
        @email = TestMailer.deliver_test_multipart(:real)
        @html = html_part(@email)
        @html.should match(/<p class="text" style="color: #0f0">/)
      end

      it "should combine different properties for one element" do
        css_rules <<-EOF
          .text { font-size: 14px; }
          p { color: #f00; }
        EOF
        @email = TestMailer.deliver_test_multipart(:real)
        @html = html_part(@email)
        @html.should match(/<p class="text" style="color: #f00;font-size: 14px">/)
      end
    end

    describe 'css file' do
      it "should not change the styles nothing if no css file is set" do
        css_rules <<-EOF
          .text { color: #0f0; }
          p { color: #f00; }
        EOF
        @email = TestMailer.deliver_test_multipart(nil)
        html_part(@email).should match(/<p class="text">/)
      end

      it "should raise MailStyle::CSSFileNotFound if css file does not exist" do
        lambda {
          TestMailer.deliver_test_multipart(:fake)
        }.should raise_error(MailStyle::CSSFileNotFound)
      end
    end

    it 'should support inline styles without deliver' do
      css_rules <<-EOF
        body { background: #000 }
        p { color: #f00; line-height: 1.5 }
        .text { font-size: 14px }
      EOF

      # Generate email
      @email = TestMailer.create_test_multipart(:real)
      html_part(@email).should match(/<body style="background: #000">/)
    end

    it "should have two parts" do
      @email = TestMailer.deliver_test_multipart
      @email.parts.length.should eql(2)
    end
  end

  describe "multipart mixed" do
    before(:each) { pending }

    let(:email) { TestMailer.deliver_test_nested_multipart_mixed(:real) }
    subject     { html_part(email) }
    it_should_behave_like("inline styles")
  end

  describe "inline rules" do
    before(:each) { pending }

    let(:email) { TestMailer.deliver_test_inline_rules("<style> .text { color: #f00; line-height: 1.5 } </style>") }
    subject     { html_part(email) }

    it "should style the elements with rules inside the document" do
      should match(/<p class="text" style="color:\s+#f00;\s*line-height:\s+1.5">/)
    end

    it "should remove the styles from the document" do
      should_not match(/<style/)
    end
  end

  describe "inline rules for print media" do
    before(:each) { pending }

    let(:email) { TestMailer.deliver_test_inline_rules('<style media="print"> .text { color: #f00; } </style>') }
    subject     { html_part(email) }

    it "should not change element styles" do
      should match(/<p class="text">/)
    end

    it "should not remove the styles from the document" do
      should match(/<style media="print"/)
    end
  end

  describe "inline immutable styles" do
    before(:each) { pending }

    let(:email) { TestMailer.deliver_test_inline_rules('<style data-immutable="true"> .text { color: #f00; } </style>') }
    subject     { html_part(email) }

    it "should not change element styles" do
      should match(/<p class="text">/)
    end

    it "should not remove the styles from the document" do
      should match(/<style data-immutable="true"/)
    end
  end
end