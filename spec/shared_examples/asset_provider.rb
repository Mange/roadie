shared_examples_for "asset provider role" do
  it "responds to #find_stylesheet" do
    subject.should respond_to(:find_stylesheet)
    subject.method(:find_stylesheet).arity.should == 1
  end

  it "responds to #find_stylesheet!" do
    subject.should respond_to(:find_stylesheet!)
    subject.method(:find_stylesheet!).arity.should == 1
  end
end
