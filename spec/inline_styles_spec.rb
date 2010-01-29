# coding: utf-8
require File.dirname(__FILE__) + '/spec_helper'

RAILS_ROOT = File.join(File.dirname(__FILE__), '../../../../')

# Set ActionMailer stuff
ActionMailer::Base.template_root = '.'
ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.deliveries = []
ActionMailer::Base.default_url_options[:host] = "example.com"
 
# Test Mailer
class TestMailer < ActionMailer::Base
  def test_multipart(css_file = nil)
    setup_email(css_file)
    content_type 'multipart/alternative'
    part :content_type => 'text/html', :body => '<p class="text">Hello World</p>'
    part :content_type => 'text/plain', :body => 'Hello World'
  end
  
  def test_singlepart_html(css_file = nil)
    setup_email(css_file)
    content_type 'text/html'
    body '<p class="text">Hello World</p>'
  end

  def test_singlepart_plain(css_file = nil)
    setup_email(css_file)
    content_type 'text/plain'
    body '<p class="text">Hello World</p>'
  end
  
  def test_image_urls(css_file = nil)
    setup_email(css_file)
    content_type 'multipart/alternative'
    part :content_type => 'text/html', :body => '<p id="image">Hello World</p><img src="/images/test.jpg" />'
    part :content_type => 'text/plain', :body => 'Hello World'
  end
  
  protected
  
  def setup_email(css_file = nil)
    css css_file unless css_file.nil?
    
    subject 'Test Multipart Email'
    recipients 'jimneath@googlemail.com'
    from 'jimneath@googlemail.com'
    sent_on Time.now
  end
end

describe 'Inline styles' do
  describe 'singlepart' do
    before(:each) do
      css_rules <<-EOF
        body { background: #000 }
        p { color: #f00; line-height: 1.5 }
        .text { font-size: 14px }
      EOF
    end

    it "should apply styles for text/html" do
      @email = TestMailer.deliver_test_singlepart_html(:real)
      @email.body.should match(/<body style="background: #000">/)
    end
    
    it "should do nothing for text/plain" do
      @email = TestMailer.deliver_test_singlepart_plain(:real)
      @email.body.should eql('<p class="text">Hello World</p>')
    end
  end
  
  describe 'multipart' do
    describe 'image urls' do
      before(:each) do
        # CSS rules
        css_rules <<-EOF
          p#image { background: url(../images/test-image.png)}
        EOF
      
        # Generate email
        @email = TestMailer.deliver_test_image_urls(:real)
        @html = html_part(@email)
      end
      
      it "should make the css urls absolute" do
        @html.should match(/<p.*style="background: url\(http:\/\/example\.com\/images\/test\-image\.png\)">/)
      end
      
      it "should make image sources absolute" do 
        # Note: Nokogiri loses the closing slash from the <img> tag for some reason.
        @html.should match(/<img src="http:\/\/example\.com\/images\/test\.jpg\">/)
      end
    end
    
    describe 'rendering inline styles' do
      before(:each) do
        css_rules <<-EOF
          body { background: #000 }
          .text { color: #0f0; font-size: 14px }
          p { color: #f00; line-height: 1.5 }
        EOF
      
        # Generate email
        @email = TestMailer.deliver_test_multipart(:real)
        @html = html_part(@email)
      end
      
      it "should add the correct xml namespace" do
        @html.should match(/<html xmlns="http:\/\/www\.w3\.org\/1999\/xhtml">/)
      end
      
      it "should write the xhtml 1.0 doctype" do
        @html.should match(/<!DOCTYPE html PUBLIC "-\/\/W3C\/\/DTD XHTML 1\.0 Transitional\/\/EN" "http:\/\/www.w3.org\/TR\/xhtml1\/DTD\/xhtml1-transitional\.dtd">/mi)
      end
      
      it "should write utf-8 content type meta tag" do
        @html.should match(/<head>.*<meta http\-equiv="Content\-Type" content="text\/html; charset=utf\-8">.*<\/head>/mi)
      end
      
      it "should wrap with html and body tag if missing" do
        @html.should match(/<html.*>.*<body.*>.*<\/body>.*<\/html>/m)
      end
      
      it "should add style to body" do
        @html.should match(/<body style="background: #000">/)
      end
      
      it "should add both styles to paragraph" do
        @html.should match(/<p class="text" style="color: #0f0;font-size: 14px;line-height: 1.5">/)
      end
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
      it "should do nothing if no css file is set" do
        @email = TestMailer.deliver_test_multipart(nil)
        html_part(@email).should eql('<p class="text">Hello World</p>')
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
end