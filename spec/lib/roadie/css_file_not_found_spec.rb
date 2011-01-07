require 'spec_helper'

module Roadie
  describe CSSFileNotFound do
    it "is initialized with a filename" do
      CSSFileNotFound.new('file.css').filename.should == 'file.css'
    end

    it "has a message" do
      CSSFileNotFound.new('style.css').message.should == 'Could not find style.css'
    end
  end
end
