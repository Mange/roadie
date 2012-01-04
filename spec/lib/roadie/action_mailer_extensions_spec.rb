# coding: utf-8
require 'spec_helper'

module Roadie
  describe ActionMailerExtensions, "CSS selection" do
    mailer = Class.new(AnonymousMailer) do
      default :css => :default

      def default_css
        mail(:subject => "Default CSS") do |format|
          format.html { render :text => '' }
        end
      end

      def override_css(css)
        mail(:subject => "Default CSS", :css => css) do |format|
          format.html { render :text => '' }
        end
      end
    end

    def expect_global_css(files)
      Roadie.should_receive(:inline_css).with(provider, files, anything, anything).and_return('')
    end

    let(:provider) { double("asset provider", :all => '') }

    before(:each) do
      Roadie.stub(:inline_css => 'unexpected value passed to inline_css')
      Roadie.stub(:current_provider => provider)
    end

    it "uses no global CSS when :css is set to nil" do
      expect_global_css []
      mailer.override_css(nil)
    end

    it "uses no global CSS when :css is set to false" do
      expect_global_css []
      mailer.override_css(false)
    end

    it "uses the default CSS when :css is not specified" do
      expect_global_css ['default']
      mailer.default_css
    end

    it "uses the specified CSS instead of the default" do
      expect_global_css ['some', 'other/files']
      mailer.override_css([:some, 'other/files'])
    end
  end

  describe ActionMailerExtensions, "using HTML" do
    mailer = Class.new(AnonymousMailer) do
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

    let(:provider) { double("asset provider", :all => '') }

    before(:each) do
      Roadie.stub(:inline_css => 'unexpected value passed to inline_css')
      Roadie.stub(:current_provider => provider)
    end

    describe "for singlepart text/plain" do
      it "does not touch the email body" do
        Roadie.should_not_receive(:inline_css)
        mailer.singlepart_plain
      end
    end

    describe "for singlepart text/html" do
      it "inlines css to the email body" do
        Roadie.should_receive(:inline_css).with(provider, ['simple'], 'Hello HTML', anything).and_return('html')
        mailer.singlepart_html.body.decoded.should == 'html'
      end
    end

    describe "for multipart" do
      it "keeps both parts" do
        mailer.multipart.should have(2).parts
      end

      it "inlines css to the email's html part" do
        Roadie.should_receive(:inline_css).with(provider, ['simple'], 'Hello HTML', anything).and_return('html')
        email = mailer.multipart
        email.html_part.body.decoded.should == 'html'
        email.text_part.body.decoded.should == 'Hello Text'
      end
    end
  end
end
