require 'spec_helper'

module Roadie
  describe StyleAttributeBuilder do
    it "sorts the added properties" do
      builder = StyleAttributeBuilder.new

      builder << StyleProperty.new("color", "green", true, 1)
      builder << StyleProperty.new("font-size", "110%", false, 15)
      builder << StyleProperty.new("color", "red", false, 15)

      expect(builder.attribute_string).to eq "font-size:110%;color:red;color:green !important"
    end

    it "preserves the order of added attributes with the same specificity" do
      builder = StyleAttributeBuilder.new

      builder << StyleProperty.new("color", "pink",  false, 50)
      builder << StyleProperty.new("color", "red",   false, 50)
      builder << StyleProperty.new("color", "green", false, 50)

      # We need one different element to trigger the problem with Ruby's
      # unstable sort
      builder << StyleProperty.new("background", "white", false, 1)

      expect(builder.attribute_string).to eq "background:white;color:pink;color:red;color:green"
    end

    it "removes duplicate properties" do
      builder = StyleAttributeBuilder.new

      builder << StyleProperty.new("color", "pink",  false, 10)
      builder << StyleProperty.new("color", "green", false, 20)
      builder << StyleProperty.new("color", "pink",  false, 50)

      expect(builder.attribute_string).to eq "color:green;color:pink"
    end
  end
end
