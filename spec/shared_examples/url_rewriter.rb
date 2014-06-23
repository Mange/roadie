shared_examples_for "url rewriter" do
  it "is constructed with a generator" do
    generator = double "URL generator"
    expect {
      described_class.new(generator)
    }.to_not raise_error
  end

  it "has a #transform_dom(dom) method that returns nil" do
    expect(subject).to respond_to(:transform_dom)
    expect(subject.method(:transform_dom).arity).to eq(1)

    dom = Nokogiri::HTML.parse "<body></body>"
    expect(subject.transform_dom(dom)).to be_nil
  end

  it "has a #transform_css(css) method that returns nil" do
    expect(subject).to respond_to(:transform_css)
    expect(subject.method(:transform_css).arity).to eq(1)

    expect(subject.transform_css("")).to be_nil
  end
end
