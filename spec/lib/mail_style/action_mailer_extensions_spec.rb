# coding: utf-8
require 'spec_helper'

describe MailStyle::ActionMailerExtensions, "inlining styles" do
  class InliningMailer < ActionMailer::Base
    default :css => :simple

    configure do
      default_url_options = {:host => "example.org"}
    end

    def multipart
      mail(:subject => "Multipart email") do |format|
        format.html { render :text => 'Hello HTML' }
        format.text { render :text => 'Hello Text' }
      end
    end

    # Not sure how to implement this one.
    # TODO: Either remove or implement
    def nested_multipart_mixed(css_file = nil)
      raise "Nested multipart mixed is not implemented"
      content_type "multipart/mixed"
      part :content_type => "multipart/alternative", :content_disposition => "inline" do |p|
        p.part :content_type => 'text/html', :body => 'Hello HTML'
        p.part :content_type => 'text/plain', :body => 'Hello Text'
      end
    end

    def singlepart_html
      mail(:subject => "HTML email") do |format|
        format.html { render :text => 'Hello HTML' }
      end
    end

    def singlepart_plain
      mail(:subject => "Text email") do |format|
        format.text { render :text => 'Hello Text' }
      end
    end
  end

  before(:each) do
    MailStyle.stub!(:load_css => 'loaded css')
    MailStyle.stub!(:inline_css => 'unexpected value') # Make sure a implementation problem doesn't hurt these examples
  end

  describe "for singlepart text/plain" do
    it "should not touch the email body" do
      MailStyle.should_not_receive(:inline_css)
      InliningMailer.singlepart_plain
    end
  end

  describe "for singlepart text/html" do
    it "should inline css to the email body" do
      MailStyle.should_receive(:inline_css).with(anything, 'Hello HTML', anything).and_return('html')
      InliningMailer.singlepart_html.body.decoded.should == 'html'
    end
  end

  describe "for multipart" do
    it "should keep both parts" do
      InliningMailer.multipart.should have(2).parts
    end

    it "should inline css to the email's html part" do
      MailStyle.should_receive(:inline_css).with(anything, 'Hello HTML', anything).and_return('html')
      email = InliningMailer.multipart
      email.parts.find { |part| part.mime_type == 'text/html' }.body.decoded.should == 'html'
      email.parts.find { |part| part.mime_type == 'text/plain' }.body.decoded.should == 'Hello Text'
    end
  end
end

describe MailStyle::ActionMailerExtensions, "loading css files" do
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
        Proc.new { |format| format.html { render :text => '' } }
      end
  end

  before(:each) do
    MailStyle.stub!(:inline_css => 'html')
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