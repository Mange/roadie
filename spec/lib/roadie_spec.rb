require 'spec_helper'

describe Roadie do
  describe ".inline_css" do
    it "creates an instance of Roadie::Inliner and execute it" do
      Roadie::Inliner.should_receive(:new).with('attri', 'butes').and_return(double('inliner', :execute => 'html'))
      Roadie.inline_css('attri', 'butes').should == 'html'
    end
  end

  describe ".load_css(root, targets)" do
    let(:fixtures_root) { Pathname.new(__FILE__).dirname.join('..', 'fixtures', 'public', 'stylesheets') }

    it "loads files matching the target names under root/public/stylesheets" do
      Roadie.load_css(fixtures_root, ['foo']).should == 'contents of foo'
      Roadie.load_css(fixtures_root, ['foo.css']).should == 'contents of foo'
    end

    it "loads files in order and join them with a newline" do
      Roadie.load_css(fixtures_root, %w[foo bar]).should == "contents of foo\ncontents of bar"
      Roadie.load_css(fixtures_root, %w[bar foo]).should == "contents of bar\ncontents of foo"
    end

    it "raises a Roadie::CSSFileNotFound error when a css file could not be found" do
      expect { Roadie.load_css(fixtures_root, ['not_here']) }.to raise_error(Roadie::CSSFileNotFound, /not_here/)
    end
  end
end
