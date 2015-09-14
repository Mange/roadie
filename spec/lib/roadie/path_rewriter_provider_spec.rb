require 'spec_helper'
require 'roadie/rspec'
require 'shared_examples/asset_provider'

module Roadie
  describe PathRewriterProvider do
    let(:upstream) { TestProvider.new "good.css" => "body { color: green; }" }

    subject(:provider) do
      PathRewriterProvider.new(upstream) do |path|
        path.gsub('well', 'good')
      end
    end

    it_behaves_like "roadie asset provider", valid_name: "well.css", invalid_name: "bad"

    it "does not call the upstream provider if block returns nil" do
      provider = PathRewriterProvider.new(upstream) { nil }
      expect(upstream).to_not receive(:find_stylesheet)
      expect(upstream).to_not receive(:find_stylesheet!)

      expect(provider.find_stylesheet("foo")).to be_nil
      expect {
        provider.find_stylesheet!("foo")
      }.to raise_error(CssNotFound, /nil/)
    end

    it "does not call the upstream provider if block returns false" do
      provider = PathRewriterProvider.new(upstream) { false }
      expect(upstream).to_not receive(:find_stylesheet)
      expect(upstream).to_not receive(:find_stylesheet!)

      expect(provider.find_stylesheet("foo")).to be_nil
      expect {
        provider.find_stylesheet!("foo")
      }.to raise_error(CssNotFound, /false/)
    end
  end
end
