require 'spec_helper'

module Roadie
  describe StyleAttributeBuilder do
    it "sorts the added properties" do
      builder = StyleAttributeBuilder.new
      builder << StyleProperty.new("color", "green", true, 1)
      builder << StyleProperty.new("font-size", "110%", false, 15)
      builder << StyleProperty.new("color", "red", false, 15)

      expect(builder.attribute_string).to eq "color:red;font-size:110%;color:green !important"
    end
  end
end
