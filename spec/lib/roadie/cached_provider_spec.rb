require 'spec_helper'
require 'roadie/rspec'
require 'shared_examples/asset_provider'

module Roadie
  describe CachedProvider do
    let(:upstream) { TestProvider.new("good.css" => "body { color: green; }") }
    let(:cache) { Hash.new }
    subject(:provider) { CachedProvider.new(upstream, cache) }

    it_behaves_like "roadie asset provider", valid_name: "good.css", invalid_name: "bad.css"

    it "stores retrieved stylesheets in the cache" do
      found = nil

      expect {
        found = provider.find_stylesheet("good.css")
      }.to change(cache, :keys).to(["good.css"])

      expect(cache["good.css"]).to eq found
    end

    it "reads from the cache first" do
      found = upstream.find_stylesheet!("good.css")

      cache["good.css"] = found

      expect(upstream).to_not receive(:find_stylesheet)
      expect(provider.find_stylesheet("good.css")).to eq found
      expect(provider.find_stylesheet!("good.css")).to eq found
    end

    it "stores failed lookups in the cache" do
      expect {
        provider.find_stylesheet("foo.css")
      }.to change(cache, :keys).to(["foo.css"])
      expect(cache["foo.css"]).to be_nil
    end

    it "stores failed lookups even when raising errors" do
      expect {
        provider.find_stylesheet!("bar.css")
      }.to raise_error CssNotFound
      expect(cache.keys).to include "bar.css"
      expect(cache["bar.css"]).to be_nil
    end

    it "defaults to a hash for cache storage" do
      expect(CachedProvider.new(upstream).cache).to be_kind_of Hash
    end
  end
end
