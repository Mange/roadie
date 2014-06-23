# encoding: UTF-8
require 'spec_helper'
require 'shared_examples/asset_provider'

module Roadie
  describe NullProvider do
    it_behaves_like "asset provider role"

    def expect_empty_stylesheet(stylesheet)
      expect(stylesheet).not_to be_nil
      expect(stylesheet.name).to eq("(null)")
      expect(stylesheet).to have(0).blocks
      expect(stylesheet.to_s).to be_empty
    end

    it "finds an empty stylesheet for every name" do
      expect_empty_stylesheet NullProvider.new.find_stylesheet("omg wtf bbq")
      expect_empty_stylesheet NullProvider.new.find_stylesheet!("omg wtf bbq")
    end
  end
end
