require 'spec_helper'

describe Roadie do
  describe ".inline_css" do
    it "creates an instance of Roadie::Inliner and execute it" do
      Roadie::Inliner.should_receive(:new).with('attri', 'butes').and_return(double('inliner', :execute => 'html'))
      Roadie.inline_css('attri', 'butes').should == 'html'
    end
  end

  describe ".app" do
    it "delegates to Rails.application" do
      Rails.stub(:application => 'application')
      Roadie.app.should == 'application'
    end
  end

  describe ".providers" do
    it "returns an array of all provider classes" do
      Roadie.should have(2).providers
      Roadie.providers.should include(Roadie::AssetPipelineProvider, Roadie::FilesystemProvider)
    end
  end

  describe ".current_provider" do
    let(:provider) { double("provider instance") }

    context "with a set provider in the config" do
      it "uses the set provider" do
        Roadie.app.config.roadie.provider = provider
        Roadie.current_provider.should == provider
      end
    end

    context "with rails' asset pipeline enabled" do
      before(:each) { Roadie.app.config.assets.enabled = true }

      it "uses the AssetPipelineProvider" do
        Roadie::AssetPipelineProvider.should_receive(:new).and_return(provider)
        Roadie.current_provider.should == provider
      end
    end

    context "with rails' asset pipeline disabled" do
      before(:each) { Roadie.app.config.assets.enabled = false }

      it "uses the FilesystemProvider" do
        Roadie::FilesystemProvider.should_receive(:new).and_return(provider)
        Roadie.current_provider.should == provider
      end
    end
  end
end
