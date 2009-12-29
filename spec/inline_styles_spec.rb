# coding: utf-8
require File.dirname(__FILE__) + '/spec_helper'

RAILS_ROOT = File.join(File.dirname(__FILE__), '../../../../')

# Set Action
ActionMailer::Base.template_root = '.'
ActionMailer::Base.delivery_method = :test
 
# Test Mailer
class TestMailer < ActionMailer::Base
  def test_multipart(css_file = nil)
    setup_email(css_file)
    content_type 'multipart/alternative'
    part :content_type => 'text/html', :body => '<p class="text">Hello World</p>'
    part :content_type => 'text/plain', :body => 'Hello World'
  end
  
  protected
  
  def setup_email(css_file = nil)
    css css_file
    subject 'Test Multipart Email'
    recipients 'jimneath@googlemail.com'
    from 'jimneath@googlemail.com'
    sent_on Time.now
  end
end

describe 'Inline styles' do
  describe 'multipart' do
    describe 'rendering inline styles' do
      before(:each) do
        # Css Rules
        css_rules = <<-EOF
          body { background: #000 }
          p { color: #f00; line-height: 1.5 }
          .text { font-size: 14px }
        EOF
        
        # Stubs
        File.stub(:exist?).and_return(true)
        File.stub(:open).and_return(StringIO.new(css_rules))
        
        # Generate email
        @email = TestMailer.deliver_test_multipart(:real)
        @html = html_part(@email)
      end
      
      it "should wrap with html and body tag if missing" do
        pending "Error with body being truncated"
        @html.should match(/<body.*>/)
      end
    end
    
    describe 'css file' do
      it "should do nothing if no css file is set" do
        @email = TestMailer.deliver_test_multipart
        html_part(@email).should eql('<p class="text">Hello World</p>')
      end
      
      it "should raise Shemail::CSSFileNotFound if css file does not exist" do
        lambda {
          TestMailer.deliver_test_multipart(:fake)
        }.should raise_error(Shemail::CSSFileNotFound)
      end
    end
    
    it "should have two parts" do
      @email = TestMailer.deliver_test_multipart
      @email.parts.length.should eql(2)
    end
  end
end