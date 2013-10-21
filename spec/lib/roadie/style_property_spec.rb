require 'spec_helper'

module Roadie
  describe StyleProperty do
    it "is initialized with a property, value, if it is marked as important, and the specificity" do
      StyleProperty.new('color', 'green', true, 45).tap do |declaration|
        declaration.property.should == 'color'
        declaration.value.should == 'green'
        declaration.should be_important
        declaration.specificity.should == 45
      end
    end

    describe "string representation" do
      it "is the property and the value joined with a colon" do
        StyleProperty.new('color', 'green', false, 1).to_s.should == 'color:green'
        StyleProperty.new('font-size', '1.1em', false, 1).to_s.should == 'font-size:1.1em'
      end

      it "contains the !important flag when set" do
        StyleProperty.new('color', 'green', true, 1).to_s.should == 'color:green !important'
      end
    end

    describe "comparing" do
      def declaration(specificity, important = false)
        StyleProperty.new('color', 'green', important, specificity)
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

    describe "parsing" do
      def parsing(declaration, specificity)
        property = StyleProperty.parse(declaration, specificity)
        [property.property, property.value, property.important?, property.specificity]
      end

      it "understands simple declarations" do
        parsing("color: green", 1).should == ["color", "green", false, 1]
        parsing(" color:green; ", 1).should == ["color", "green", false, 1]
        parsing("color: green  ", 1).should == ["color", "green", false, 1]
        parsing("color: green  ; ", 1).should == ["color", "green", false, 1]
      end

      it "understands more complex values" do
        parsing("padding:0 1px 5rem 9%;", 89).should == ["padding", "0 1px 5rem 9%", false, 89]
      end

      it "understands more complex names" do
        parsing("font-size: 50%", 10).should == ["font-size", "50%", false, 10]
      end

      it "correctly reads !important declarations" do
        parsing("color: green !important", 1).should == ["color", "green", true, 1]
        parsing("color: green !important;", 1).should == ["color", "green", true, 1]
      end

      it "raises an error on unparseable declarations" do
        expect {
          parsing("I want a red apple!", 1)
        }.to raise_error(Roadie::UnparseableDeclaration, /red apple/)
      end
    end
  end
end
