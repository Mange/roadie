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

    it "is enumerable" do
      provider.should be_kind_of(Enumerable)
      provider.should respond_to(:each)
      provider.each.to_a.should == [test_provider]
    end

    it "has a size" do
      provider.size.should == 1
    end

    it "can have providers pushed and popped" do
      other = double "Some other provider"

      expect {
        provider.push other
      }.to change(provider, :size).by(1)

      expect {
        provider.pop.should == other
      }.to change(provider, :size).by(-1)
    end

    it "can have providers shifted and unshifted" do
      other = double "Some other provider"

      expect {
        provider.unshift other
      }.to change(provider, :size).by(1)

      expect {
        provider.shift.should == other
      }.to change(provider, :size).by(-1)
    end
  end
end
