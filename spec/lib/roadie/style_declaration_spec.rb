require 'spec_helper'

module Roadie
  describe StyleDeclaration do
    it "is initialized with a property, value, if it is marked as important, and the specificity" do
      StyleDeclaration.new('color', 'green', true, 45).tap do |declaration|
        declaration.property.should == 'color'
        declaration.value.should == 'green'
        declaration.should be_important
        declaration.specificity.should == 45
      end
    end

    describe "string representation" do
      it "is the property and the value joined with a colon" do
        StyleDeclaration.new('color', 'green', false, 1).to_s.should == 'color:green'
        StyleDeclaration.new('font-size', '1.1em', false, 1).to_s.should == 'font-size:1.1em'
      end
    end

    describe "comparing" do
      def declaration(specificity, important = false)
        StyleDeclaration.new('color', 'green', important, specificity)
      end

      it "compares on specificity" do
        declaration(5).should be == declaration(5)
        declaration(4).should be < declaration(5)
        declaration(6).should be > declaration(5)
      end

      context "with an important declaration" do
        it "is less than the important declaration regardless of the specificity" do
          declaration(99, false).should be < declaration(1, true)
        end

        it "compares like normal when both declarations are important" do
          declaration(5, true).should be == declaration(5, true)
          declaration(4, true).should be < declaration(5, true)
          declaration(6, true).should be > declaration(5, true)
        end
      end
    end
  end
end
