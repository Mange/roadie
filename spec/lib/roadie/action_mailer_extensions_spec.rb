# coding: utf-8
require 'spec_helper'

describe Roadie::ActionMailerExtensions, "inlining styles" do
  class InliningMailer < ActionMailer::Base
    default :css => :simple

    def multipart
      mail(:subject => "Multipart email") do |format|
        format.html { render :text => 'Hello HTML' }
        format.text { render :text => 'Hello Text' }
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
  let(:provider) { double("asset provider", :load_css => '') }

  before(:each) do
    Roadie.stub!(:inline_css => 'unexpected value passed to inline_css')
    Roadie::AssetPipelineProvider.stub(:new => provider)
  end

  describe "for singlepart text/plain" do
    it "does not touch the email body" do
      Roadie.should_not_receive(:inline_css)
      InliningMailer.singlepart_plain
    end
  end

  describe "for singlepart text/html" do
    it "inlines css to the email body" do
      Roadie.should_receive(:inline_css).with(anything, 'Hello HTML', provider, anything).and_return('html')
      InliningMailer.singlepart_html.body.decoded.should == 'html'
    end
  end

  describe "for multipart" do
    it "keeps both parts" do
      InliningMailer.multipart.should have(2).parts
    end

    it "inlines css to the email's html part" do
      Roadie.should_receive(:inline_css).with(anything, 'Hello HTML', provider, anything).and_return('html')
      email = InliningMailer.multipart
      email.html_part.body.decoded.should == 'html'
      email.text_part.body.decoded.should == 'Hello Text'
    end
  end
end

describe Roadie::ActionMailerExtensions, "loading css files" do
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
  let(:provider) { double("asset provider") }

  before(:each) do
    Roadie.stub!(:inline_css => 'html')
    Roadie::AssetPipelineProvider.stub(:new => provider)
  end

  it "loads css from via the asset provider" do
    provider.should_receive(:load_css).with(anything).and_return('')
    CssLoadingMailer.use_default
  end

  it "loads the css specified in the default mailer settings" do
    provider.should_receive(:load_css).with(['default_value']).and_return('')
    CssLoadingMailer.use_default
  end

  it "loads the css specified in the specific mailer action instead of the default choice" do
    provider.should_receive(:load_css).with(['specific']).and_return('')
    CssLoadingMailer.override(:specific)
  end

  it "loads no css when specifying false in the mailer action" do
    provider.should_not_receive(:load_css)
    CssLoadingMailer.override(false)
  end

  it "loads multiple css files when given an array" do
    provider.should_receive(:load_css).with(['specific', 'other']).and_return('')
    CssLoadingMailer.override([:specific, :other])
  end
end
