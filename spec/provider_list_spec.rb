# encoding: UTF-8
require 'spec_helper'
require 'shared_examples/asset_provider_examples'

module Roadie
  describe ProviderList do
    let(:test_provider) { TestProvider.new }
    subject(:provider) { ProviderList.new([test_provider]) }

    it_behaves_like "asset provider"

    it "finds using all given providers" do
      first = TestProvider.new "foo.css" => "foo"
      second = TestProvider.new "bar.css" => "bar"
      provider = ProviderList.new [first, second]

      provider.find_stylesheet("foo.css").should == "foo"
      provider.find_stylesheet("bar.css").should == "bar"
      provider.find_stylesheet("baz.css").should be_nil
    end
  end
end
