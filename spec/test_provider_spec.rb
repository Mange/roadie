require 'spec_helper'
require 'shared_examples/asset_provider_examples'

describe TestProvider do
  subject(:provider) { TestProvider.new }

  it_behaves_like "asset provider"

  it "finds styles from a predefined hash" do
    provider = TestProvider.new({
      "foo.css" => "a { color: red; }",
      "bar.css" => "body { color: green; }",
    })
    provider.find_stylesheet("foo.css").should == "a { color: red; }"
    provider.find_stylesheet("bar.css").should == "body { color: green; }"
    provider.find_stylesheet("baz.css").should be_nil
  end

  it "can have a default for missing entries" do
    provider = TestProvider.new({
      "foo.css" => "a { color: red; }",
      :default  => "body { color: green; }",
    })
    provider.find_stylesheet("foo.css").should == "a { color: red; }"
    provider.find_stylesheet("bar.css").should == "body { color: green; }"
  end
end
