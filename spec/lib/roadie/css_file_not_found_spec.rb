require 'spec_helper'

module Roadie
  describe CSSFileNotFound do
    it "is initialized with a filename" do
      CSSFileNotFound.new('file.css').filename.should == 'file.css'
    end

    it "can be initialized with the guess the filename was based on" do
      CSSFileNotFound.new('file.css', :file).guess.should == :file
    end

    it "has a nil guess when no guess was specified" do
      CSSFileNotFound.new('').guess.should be_nil
    end

    context "without a guess" do
      it "has a message with the wanted filename" do
        CSSFileNotFound.new('style.css').message.should == 'Could not find style.css'
      end
    end

    context "with a guess" do
      it "has a message with the wanted filename and the guess" do
        CSSFileNotFound.new('style.css', :style).message.should == 'Could not find style.css (guessed from :style)'
      end
    end
  end
end
