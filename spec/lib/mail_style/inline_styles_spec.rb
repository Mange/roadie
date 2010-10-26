# coding: utf-8
require 'spec_helper'

# Set ActionMailer stuff
ActionMailer::Base.prepend_view_path '.'
ActionMailer::Base.deliveries = []

# Test Mailer
class TestMailer < ActionMailer::Base
  default :from => "john@example.com", :to => "doe@example.com", :css => :simple

  def multipart
    mail(:subject => "Multipart email") do |format|
      format.html { render :text => '<p class="text">Hello <a href="http://example.com/">World</a></p>' }
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
    mail(:subject => "Inline rules email", :css => false) do |format|
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

  def image_urls
    mail(:subject => "Image URLs email", :css => :image) do |format|
      format.html { render :text => '<p id="image">Hello World</p><p id="image2">Goodbye World</p><img src="/images/test.jpg" />' }
      format.text { render :text => 'Hello World' }
    end
  end
end

ActionMailer::Base.configure do |config|
  config.perform_deliveries = false
  config.default_url_options = {:host => "example.com"}
end

shared_examples_for "inline styles" do
  use_css 'simple', <<-CSS
    body { background: #000 }
    p { color: #f00; line-height: 1.5 }
    .text { font-size: 14px }
  CSS

  it "should add the correct xml namespace" do
    should include('<html xmlns="http://www.w3.org/1999/xhtml')
  end

  it "should write the xhtml 1.0 doctype" do
    should include('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">')
  end

  it "should write utf-8 content type meta tag" do
    should match(/<head>.*<meta http\-equiv="Content\-Type" content="text\/html; charset=utf\-8">.*<\/head>/mi)
  end

  it "should wrap with html and body tag if missing" do
    should match(/<html.*>.*<body.*>.*<\/body>.*<\/html>/m)
  end

  it "should add styles from selectors in css ruleset" do
    should match(/<body style="background: #000">/)
  end
end

describe MailStyle::InlineStyles do
  let(:text_body) { email.parts.find { |part| part.mime_type == 'text/plain' }.body.to_s }
  let(:html_body) { email.parts.find { |part| part.mime_type == 'text/html' }.body.to_s }
  let(:body) { email.body.to_s }

  use_css 'simple', <<-CSS
    body { background: #000 }
    p { color: #f00; line-height: 1.5 }
    .text { font-size: 14px }
    a:link { color: #f00 }
  CSS

  use_css 'image', <<-EOF
    p#image { background: url(../images/test-image.png) }
    p#image2 { background: url("../images/test-image2.png") }
  EOF

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
    let(:email) { TestMailer.multipart }

    it "should have two parts" do
      email.should have(2).parts
    end

    describe 'rendering inline styles' do
      subject { html_body }
      it_should_behave_like("inline styles")
    end

    describe 'image urls' do
      let(:email) { TestMailer.image_urls }

      it "should make the css urls absolute" do
        html_body.should include('background: url(http://example.com/images/test-image.png)')
        html_body.should include('background: url("http://example.com/images/test-image2.png")')
      end

      it "should make image sources absolute" do
        html_body.should include('src="http://example.com/images/test.jpg"')
      end
    end

    describe 'combining styles' do
      it "should select the most specific style" do
        # Note: This test is next to useless right now
        html_body.should include('color: #f00;')
      end

      it "should combine different properties for one element" do
        # Note: This test is next to useless right now
        html_body.should include('color: #f00;')
        html_body.should include('font-size: 14px;')
      end
    end
  end

  describe "inline rules" do
    let(:email) { TestMailer.inline_rules("<style> .text { color: #f00; line-height: 1.5 } </style>") }
    subject     { html_body }

    it "should style the elements with rules inside the document" do
      should match(/<p class="text" style="color:\s+#f00;\s*line-height:\s+1.5">/)
    end

    it "should remove the styles from the document" do
      should_not include('<style')
    end
  end

  describe "inline rules for print media" do
    let(:email) { TestMailer.inline_rules('<style media="print"> .text { color: #f00; } </style>') }
    subject     { html_body }

    it "should not change element styles" do
      should match(/<p class="text">/)
    end

    it "should not remove the styles from the document" do
      should match(/<style media="print"/)
    end
  end

  describe "inline immutable styles" do
    let(:email) { TestMailer.inline_rules('<style data-immutable="true"> .text { color: #f00; } </style>') }
    subject     { html_body }

    it "should not change element styles" do
      should match(/<p class="text">/)
    end

    it "should not remove the styles from the document" do
      should match(/<style data-immutable="true"/)
    end
  end
end

describe MailStyle::InlineStyles, "loading css files" do
  class CssLoadingMailer < ActionMailer::Base
    default :css => :default_value
    def use_default
      mail &with_empty_html_response
    end

    def override(target)
      mail :css => target, &with_empty_html_response
    end

    protected
      def with_empty_html_response
        Proc.new { |format| format.html { render :text => '<p></p>' } }
      end
  end

  it "should load the css specified in the default mailer settings" do
    MailStyle.should_receive(:load_css).with(Rails.root, ['default_value']).and_return('')
    CssLoadingMailer.use_default
  end

  it "should load the css specified in the specific mailer action instead of the default choice" do
    MailStyle.should_receive(:load_css).with(Rails.root, ['specific']).and_return('')
    CssLoadingMailer.override(:specific)
  end

  it "should load no css when specifying false in the mailer action" do
    MailStyle.should_not_receive(:load_css)
    CssLoadingMailer.override(false)
  end

  it "should load multiple css files when given an array" do
    MailStyle.should_receive(:load_css).with(Rails.root, ['specific', 'other']).and_return('')
    CssLoadingMailer.override([:specific, :other])
  end
end