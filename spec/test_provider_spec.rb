require 'spec_helper'
require 'shared_examples/asset_provider_examples'

describe TestProvider do
  subject(:provider) { TestProvider.new }

  it_behaves_like Roadie::AssetProvider

  it "finds styles from a predefined hash" do
    provider = TestProvider.new("/assets", {
      "foo.css" => "a { color: red; }",
      "bar.css" => "body { color: green; }",
    })
    provider.find("/assets/foo.css").should == "a { color: red; }"
    provider.find("bar.css").should == "body { color: green; }"
    expect { provider.find("baz.css") }.to raise_error Roadie::CSSFileNotFound
  end

  it "can have a default for missing entries" do
    provider = TestProvider.new("/assets", {
      "foo.css" => "a { color: red; }",
      :default  => "body { color: green; }",
    })
    provider.find("/assets/foo.css").should == "a { color: red; }"
    provider.find("bar.css").should == "body { color: green; }"
  end

  it "does not require a passed prefix" do
    provider = TestProvider.new "foo.css" => "foo"
    provider.find("foo.css").should == "foo"
  end
end
