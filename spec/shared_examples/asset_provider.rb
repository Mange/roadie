# TODO: How do we expose this so clients can test their own asset providers?

shared_examples_for "asset provider" do
  it "responds to #find_stylesheet" do
    subject.should respond_to(:find_stylesheet)
    subject.method(:find_stylesheet).arity.should == 1
  end

  it "responds to #find_stylesheet!" do
    subject.should respond_to(:find_stylesheet!)
    subject.method(:find_stylesheet!).arity.should == 1
  end
end

shared_examples_for "delegating find_stylesheet! method" do
  describe "#find_stylesheet!" do
    it "delegates to #find_stylesheet" do
      subject.should_receive(:find_stylesheet).with("filename").and_return "foo"
      subject.find_stylesheet!("filename").should == "foo"
    end

    it "raises CssNotFound on nil" do
      subject.stub find_stylesheet: nil

      expect {
        subject.find_stylesheet!("missing.css")
      }.to raise_error Roadie::CssNotFound, /missing\.css/
    end
  end
end
