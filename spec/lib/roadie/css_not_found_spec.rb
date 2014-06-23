require 'spec_helper'

module Roadie
  describe CssNotFound do
    it "is initialized with a name" do
      error = CssNotFound.new('style.css')
      expect(error.css_name).to eq('style.css')
      expect(error.message).to eq('Could not find stylesheet "style.css"')
    end

    it "can be initialized with an extra message" do
      expect(CssNotFound.new('file.css', "directory is missing").message).to eq(
        'Could not find stylesheet "file.css": directory is missing'
      )
    end
  end
end
