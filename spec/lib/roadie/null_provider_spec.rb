# encoding: UTF-8
require 'spec_helper'
require 'shared_examples/asset_provider'

module Roadie
  describe NullProvider do
    it_behaves_like "asset provider role"

    def expect_empty_stylesheet(stylesheet)
      stylesheet.should_not be_nil
      stylesheet.name.should == "(null)"
      stylesheet.should have(0).blocks
      stylesheet.to_s.should be_empty
    end

    it "finds an empty stylesheet for every name" do
      expect_empty_stylesheet NullProvider.new.find_stylesheet("omg wtf bbq")
      expect_empty_stylesheet NullProvider.new.find_stylesheet!("omg wtf bbq")
    end
  end
end
