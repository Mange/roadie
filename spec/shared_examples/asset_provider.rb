shared_examples_for "asset provider role" do
  it "responds to #find_stylesheet" do
    expect(subject).to respond_to(:find_stylesheet)
    expect(subject.method(:find_stylesheet).arity).to eq(1)
  end

  it "responds to #find_stylesheet!" do
    expect(subject).to respond_to(:find_stylesheet!)
    expect(subject.method(:find_stylesheet!).arity).to eq(1)
  end
end
