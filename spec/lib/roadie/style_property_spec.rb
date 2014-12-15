require 'spec_helper'

module Roadie
  describe StyleProperty do
    it "is initialized with a property, value, if it is marked as important, and the specificity" do
      StyleProperty.new('color', 'green', true, 45).tap do |declaration|
        expect(declaration.property).to eq('color')
        expect(declaration.value).to eq('green')
        expect(declaration).to be_important
        expect(declaration.specificity).to eq(45)
      end
    end

    describe "string representation" do
      it "is the property and the value joined with a colon" do
        expect(StyleProperty.new('color', 'green', false, 1).to_s).to eq('color:green')
        expect(StyleProperty.new('font-size', '1.1em', false, 1).to_s).to eq('font-size:1.1em')
      end

      it "contains the !important flag when set" do
        expect(StyleProperty.new('color', 'green', true, 1).to_s).to eq('color:green !important')
      end
    end

    describe "comparing" do
      def declaration(specificity, important = false)
        StyleProperty.new('color', 'green', important, specificity)
      end

      it "compares on specificity" do
        expect(declaration(5)).to eq(declaration(5))
        expect(declaration(4)).to be < declaration(5)
        expect(declaration(6)).to be > declaration(5)
      end

      context "with an important declaration" do
        it "is less than the important declaration regardless of the specificity" do
          expect(declaration(99, false)).to be < declaration(1, true)
        end

        it "compares like normal when both declarations are important" do
          expect(declaration(5, true)).to eq(declaration(5, true))
          expect(declaration(4, true)).to be < declaration(5, true)
          expect(declaration(6, true)).to be > declaration(5, true)
        end
      end
    end
  end
end
