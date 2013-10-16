# encoding: UTF-8
require 'spec_helper'
require 'shared_examples/asset_provider'

module Roadie
  describe NullProvider do
    it_behaves_like "asset provider role"

    it "finds the empty string for every name" do
      NullProvider.new.find_stylesheet("omg wtf bbq").should == ""
      NullProvider.new.find_stylesheet!("omg wtf bbq").should == ""
    end
  end
end
