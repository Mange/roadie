shared_examples_for "roadie asset provider" do |options|
  valid_name = options[:valid_name] or raise "You must provide a :valid_name option to the shared examples"
  invalid_name = options[:invalid_name] or raise "You must provide an :invalid_name option to the shared examples"

  def verify_stylesheet(stylesheet)
    expect(stylesheet).to_not be_nil

    # Name
    expect(stylesheet.name).to be_a(String)
    expect(stylesheet.name).to_not be_empty

    # We do not want to force clients to always return non-empty files.
    # Stylesheet#initialize should crash when given a non-valid CSS (like nil,
    # for example)
    # expect(stylesheet.blocks).to_not be_empty
  end

  it "responds to #find_stylesheet" do
    expect(subject).to respond_to(:find_stylesheet)
    expect(subject.method(:find_stylesheet).arity).to eq 1
  end

  it "responds to #find_stylesheet!" do
    expect(subject).to respond_to(:find_stylesheet!)
    expect(subject.method(:find_stylesheet!).arity).to eq 1
  end

  describe "#find_stylesheet" do
    it "can find a stylesheet" do
      verify_stylesheet subject.find_stylesheet(valid_name)
    end

    it "cannot find an invalid stylesheet" do
      expect(subject.find_stylesheet(invalid_name)).to be_nil
    end
  end

  describe "#find_stylesheet!" do
    it "can find a stylesheet" do
      verify_stylesheet subject.find_stylesheet!(valid_name)
    end

    it "raises Roadie::CssNotFound on invalid stylesheets" do
      expect {
        subject.find_stylesheet!(invalid_name)
      }.to raise_error Roadie::CssNotFound, Regexp.new(Regexp.quote(invalid_name))
    end
  end
end
