shared_examples_for "url rewriter" do
  it "is constructed with a generator" do
    generator = double "URL generator"
    expect {
      described_class.new(generator)
    }.to_not raise_error
  end

  it "has a #transform_dom(dom) method that returns nil" do
    subject.should respond_to(:transform_dom)
    subject.method(:transform_dom).arity.should == 1

    dom = Nokogiri::HTML.parse "<body></body>"
    subject.transform_dom(dom).should be_nil
  end

  it "has a #transform_css(css) method that returns nil" do
    subject.should respond_to(:transform_css)
    subject.method(:transform_css).arity.should == 1

    subject.transform_css("").should be_nil
  end
end
