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
end
