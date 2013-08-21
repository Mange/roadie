# TODO: How do we expose this so clients can test their own asset providers?

shared_examples_for "asset provider" do
  it "responds to #find_stylesheet"

  describe "#find_stylesheet!" do
    it "delegates to #find_stylesheet" do
      provider.should_receive(:find_stylesheet).with("filename").and_return "foo"
      provider.find_stylesheet!("filename").should == "foo"
    end

    it "raises CSSFileNotFound on nil" do
      provider.stub find_stylesheet: nil

      expect {
        provider.find_stylesheet!("missing.css")
      }.to raise_error Roadie::CSSFileNotFound, /missing\.css/
    end
  end
end
