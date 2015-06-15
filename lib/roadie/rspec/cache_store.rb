shared_examples_for "roadie cache store" do
  it "allows storing Stylesheets" do
    stylesheet = Roadie::Stylesheet.new("foo.css", "body { color: green; }")
    expect(subject["foo"] = stylesheet).to eql stylesheet
  end

  it "allows retreiving stored stylesheets" do
    stylesheet = Roadie::Stylesheet.new("foo.css", "body { color: green; }")
    subject["foo"] = stylesheet
    stored_stylesheet = subject["foo"]
    expect(stored_stylesheet.to_s).to eq stylesheet.to_s
  end

  it "defaults to nil when cache does not contain path" do
    expect(subject["bar"]).to be_nil
  end

  it "accepts nil assignments to clear cache" do
    subject["foo"] = Roadie::Stylesheet.new("", "")
    expect {
      subject["foo"] = nil
    }.to_not raise_error
    expect(subject["foo"]).to be_nil
  end
end
