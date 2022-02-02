# frozen_string_literal: true

require "spec_helper"

module Roadie
  describe CssNotFound do
    it "is initialized with a name" do
      error = CssNotFound.new(css_name: "style.css")
      expect(error.css_name).to eq("style.css")
      expect(error.message).to eq('Could not find stylesheet "style.css"')
    end

    it "can be initialized with an extra message" do
      error = CssNotFound.new(css_name: "file.css", message: "directory is missing")
      expect(error.message).to eq(
        'Could not find stylesheet "file.css": directory is missing'
      )
    end

    it "shows information about used provider when given" do
      provider = double("Some cool provider")
      error = CssNotFound.new(css_name: "style.css", provider: provider)

      expect(error.message).to eq(
        %(Could not find stylesheet "style.css"\nUsed provider:\n#{provider})
      )
    end
  end
end
