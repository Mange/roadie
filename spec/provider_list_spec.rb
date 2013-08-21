# encoding: UTF-8
require 'spec_helper'
require 'shared_examples/asset_provider_examples'

module Roadie
  describe ProviderList do
    let(:test_provider) { TestProvider.new }
    subject(:provider) { ProviderList.new([test_provider]) }

    it_behaves_like AssetProvider

    it "finds using all given providers" do
      first = TestProvider.new "foo.css" => "foo"
      second = TestProvider.new "bar.css" => "bar"
      provider = ProviderList.new [first, second]

      provider.find("foo.css").should == "foo"
      provider.find("bar.css").should == "bar"
    end

    it "raises an error when no providers can find the name" do
      expect {
        provider.find("foo.css")
      }.to raise_error CSSFileNotFound, /foo\.css/
    end
  end
end
