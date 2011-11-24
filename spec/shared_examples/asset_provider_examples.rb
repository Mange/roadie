shared_examples_for Roadie::AssetProvider do
  describe "#all(files)" do
    it "loads files in order and join them with a newline" do
      provider.should_receive(:find).with('one').twice.and_return('contents of one')
      provider.should_receive(:find).with('two').twice.and_return('contents of two')

      provider.all(%w[one two]).should == "contents of one\ncontents of two"
      provider.all(%w[two one]).should == "contents of two\ncontents of one"
    end
  end
end
