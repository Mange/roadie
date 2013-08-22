require 'spec_helper'

describe Roadie do
  let(:config) { OpenStruct.new roadie: OpenStruct.new }

  before do
    app = double("Application", config: config)
    rails = double("Rails", application: app)
    stub_const "Rails", rails
  end

  describe ".app" do
    it "delegates to Rails.application" do
      Rails.stub(:application => 'application')
      Roadie.app.should == 'application'
    end
  end

  describe ".enabled?" do
    it "returns the value of config.roadie.enabled" do
      config.roadie.enabled = true
      Roadie.should be_enabled
      config.roadie.enabled = false
      Roadie.should_not be_enabled
    end
  end

  describe ".after_inlining_handler" do
    let(:after_inlining_handler) { double("after inlining handler") }

    it "returns the value of config.roadie.after_inlining_handler" do
      config.roadie.after_inlining = after_inlining_handler
      Roadie.after_inlining_handler.should == after_inlining_handler
      config.roadie.after_inlining = nil
      Roadie.after_inlining_handler.should == nil
    end
  end
end
