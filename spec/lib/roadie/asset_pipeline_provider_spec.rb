require 'spec_helper'

module Roadie
  describe AssetPipelineProvider do
    let(:provider) { AssetPipelineProvider.new }
    subject { provider }

    it "has a configurable prefix" do
      AssetPipelineProvider.new("/prefix").prefix.should == "/prefix"
    end

    it 'has a prefix of "/assets" by default' do
      provider.prefix.should == "/assets"
    end

    describe "#find(file)" do
      let(:pipeline) { double("Rails asset pipeline") }
      before(:each) { Roadie.app.stub(:assets => pipeline) }

      def expect_pipeline_access(name, returning = '')
        pipeline.should_receive(:[]).with(name).and_return(returning)
      end

      it "loads files matching the target names in Rails assets" do
        expect_pipeline_access('foo', 'contents of foo')
        expect_pipeline_access('foo.css', 'contents of foo.css')

        provider.find('foo').should == 'contents of foo'
        provider.find('foo.css').should == 'contents of foo.css'
      end

      it "strips the contents" do
        expect_pipeline_access('foo', "   contents  \n ")
        provider.find('foo').should == "contents"
      end

      it "removes the prefix from the filename" do
        expect_pipeline_access('foo')
        expect_pipeline_access('path/to/foo')

        provider = AssetPipelineProvider.new("/prefix")
        provider.find('/prefix/foo')
        provider.find('/prefix/path/to/foo')
      end

      it "cleans up double slashes from the path" do
        expect_pipeline_access('path/to/foo')

        provider = AssetPipelineProvider.new("/prefix/")
        provider.find('/prefix/path/to//foo')
      end

      it "raises a Roadie::CSSFileNotFound error when the file could not be found" do
        expect_pipeline_access('not_here', nil)
        expect {
          provider.find('not_here')
        }.to raise_error(Roadie::CSSFileNotFound, /not_here/)
      end
    end

    describe "#all(files)" do
      it "loads files in order and join them with a newline" do
        provider.should_receive(:find).with('one').twice.and_return('contents of one')
        provider.should_receive(:find).with('two').twice.and_return('contents of two')

        provider.all(%w[one two]).should == "contents of one\ncontents of two"
        provider.all(%w[two one]).should == "contents of two\ncontents of one"
      end
    end
  end
end
