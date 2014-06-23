require 'spec_helper'
require 'roadie/rspec'

describe TestProvider do
  subject(:provider) { TestProvider.new }

  it_behaves_like "roadie asset provider", valid_name: "existing.css", invalid_name: "invalid.css" do
    subject { TestProvider.new "existing.css" => "" }
  end

  it "finds styles from a predefined hash" do
    provider = TestProvider.new({
      "foo.css" => "a { color: red; }",
      "bar.css" => "body { color: green; }",
    })
    expect(provider.find_stylesheet("foo.css").to_s).not_to include("body")
    expect(provider.find_stylesheet("bar.css").to_s).to include("body")
    expect(provider.find_stylesheet("baz.css")).to be_nil
  end

  it "can have a default for missing entries" do
    provider = TestProvider.new({
      "foo.css" => "a { color: red; }",
      :default  => "body { color: green; }",
    })
    expect(provider.find_stylesheet("foo.css").to_s).not_to include("body")
    expect(provider.find_stylesheet("bar.css").to_s).to include("body")
  end
end
