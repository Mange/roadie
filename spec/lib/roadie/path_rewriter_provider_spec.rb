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
  end
end
