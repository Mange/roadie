# encoding: UTF-8
require 'spec_helper'
require 'roadie/rspec'

module Roadie
  describe ProviderList do
    let(:test_provider) { TestProvider.new }
    subject(:provider) { ProviderList.new([test_provider]) }

    it_behaves_like "roadie asset provider", valid_name: "valid", invalid_name: "invalid" do
      let(:test_provider) { TestProvider.new "valid" => "" }
    end

    it "finds using all given providers" do
      first = TestProvider.new "foo.css" => "foo { color: green; }"
      second = TestProvider.new "bar.css" => "bar { color: green; }"
      provider = ProviderList.new [first, second]

      expect(provider.find_stylesheet("foo.css").to_s).to include "foo"
      expect(provider.find_stylesheet("bar.css").to_s).to include "bar"
      expect(provider.find_stylesheet("baz.css")).to be_nil
    end

    it "is enumerable" do
      expect(provider).to be_kind_of(Enumerable)
      expect(provider).to respond_to(:each)
      expect(provider.each.to_a).to eq([test_provider])
    end

    it "has a size" do
      expect(provider.size).to eq(1)
      expect(provider).not_to be_empty
    end

    it "has a first and a last element" do
      providers = [double("1"), double("2"), double("3")]
      list = ProviderList.new(providers)
      expect(list.first).to eq(providers.first)
      expect(list.last).to eq(providers.last)
    end

    it "can have providers pushed and popped" do
      other = double "Some other provider"

      expect {
        provider.push other
        provider << other
      }.to change(provider, :size).by(2)

      expect {
        expect(provider.pop).to eq(other)
      }.to change(provider, :size).by(-1)
    end

    it "can have providers shifted and unshifted" do
      other = double "Some other provider"

      expect {
        provider.unshift other
      }.to change(provider, :size).by(1)

      expect {
        expect(provider.shift).to eq(other)
      }.to change(provider, :size).by(-1)
    end

    it "has a readable string represenation" do
      provider = double("Provider", to_s: "Some provider")
      sublist = ProviderList.new([provider, provider])
      list = ProviderList.new([provider, sublist, provider])
      expect(list.to_s).to eql(
        "ProviderList: [\n" +
          "\tSome provider,\n" +
          "\tProviderList: [\n" +
            "\t\tSome provider,\n" +
            "\t\tSome provider\n" +
          "\t],\n" +
          "\tSome provider\n" +
        "]"
      )
    end

    it "raises a readable error message" do
      provider = double("Provider", to_s: "Some provider")
      allow(provider).to receive(:find_stylesheet!).and_raise(
        CssNotFound.new("style.css", "I tripped", provider)
      )

      sublist = ProviderList.new([provider, provider])
      list = ProviderList.new([provider, sublist, provider])

      expect { list.find_stylesheet!("style.css") }.to raise_error { |error|
        expect(error.message).to eq(
          "Could not find stylesheet \"style.css\": All providers failed\n" +
          "Used providers:\n" +
            "\tSome provider: I tripped\n" +
            "\tSome provider: I tripped\n" +
            "\tSome provider: I tripped\n" +
            "\tSome provider: I tripped\n"
        )
      }
    end

    describe "wrapping" do
      it "creates provider lists with the arguments" do
        expect(ProviderList.wrap(test_provider)).to be_instance_of(ProviderList)
        expect(ProviderList.wrap(test_provider, test_provider).size).to eq(2)
      end

      it "flattens arrays" do
        expect(ProviderList.wrap([test_provider, test_provider], test_provider).size).to eq(3)
        expect(ProviderList.wrap([test_provider, test_provider]).size).to eq(2)
      end

      it "combines with providers from other lists" do
        other_list = ProviderList.new([test_provider, test_provider])
        expect(ProviderList.wrap(test_provider, other_list).size).to eq(3)
      end

      it "returns the passed list if only a single ProviderList is passed" do
        other_list = ProviderList.new([test_provider])
        expect(ProviderList.wrap(other_list)).to eql other_list
      end
    end
  end
end
