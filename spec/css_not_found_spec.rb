require 'spec_helper'

module Roadie
  describe CssNotFound do
    it "is initialized with a name" do
      error = CssNotFound.new('style.css')
      error.css_name.should == 'style.css'
      error.message.should == 'Could not find stylesheet "style.css"'
    end

    it "can be initialized with an extra message" do
      CssNotFound.new('file.css', "directory is missing").message.should ==
        'Could not find stylesheet "file.css": directory is missing'
    end
  end
end
