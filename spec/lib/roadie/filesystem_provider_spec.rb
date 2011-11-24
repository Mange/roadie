require 'spec_helper'
require 'shared_examples/asset_provider_examples'
require 'tmpdir'

module Roadie
  describe FilesystemProvider do
    let(:provider) { FilesystemProvider.new }

    it_behaves_like AssetProvider

    it "has a configurable prefix" do
      FilesystemProvider.new("/prefix").prefix.should == "/prefix"
    end

    it "has a configurable path" do
      path = Pathname.new("/path")
      FilesystemProvider.new('', path).path.should == path
    end

    it "bases the path on the project root if passed a string with a relative path" do
      FilesystemProvider.new('', "foo/bar").path.should == Roadie.app.root.join("foo", "bar")
      FilesystemProvider.new('', "/foo/bar").path.should == Pathname.new("/foo/bar")
    end

    it 'has a path of "<root>/public/stylesheets" by default' do
      FilesystemProvider.new.path.should == Roadie.app.root.join('public', 'stylesheets')
    end

    it 'has a prefix of "/stylesheets" by default' do
      FilesystemProvider.new.prefix.should == "/stylesheets"
    end

    describe "#find(file)" do
      around(:each) do |example|
        Dir.mktmpdir do |path|
          Dir.chdir(path) { example.run }
        end
      end

      let(:provider) { FilesystemProvider.new('/prefix', Pathname.new('.')) }

      def create_file(name, contents = '')
        Pathname.new(name).tap do |path|
          path.dirname.mkpath unless path.dirname.directory?
          path.open('w') { |file| file << contents }
        end
      end

      it "loads files from the filesystem" do
        create_file('foo.css', 'contents of foo.css')
        provider.find('foo.css').should == 'contents of foo.css'
      end

      it "removes the prefix" do
        create_file('foo.css', 'contents of foo.css')
        provider.find('/prefix/foo.css').should == 'contents of foo.css'
        provider.find('prefix/foo.css').should == 'contents of foo.css'
      end

      it 'tries the filename with a ".css" extension if it does not exist' do
        create_file('bar',     'in bare bar')
        create_file('bar.css', 'in bar.css')
        create_file('foo.css', 'in foo.css')

        provider.find('bar').should == 'in bare bar'
        provider.find('foo').should == 'in foo.css'
      end

      it "strips the contents" do
        create_file('foo.css', "   contents  \n ")
        provider.find('foo.css').should == "contents"
      end

      it "supports nested directories" do
        create_file('path/to/foo.css')
        create_file('path/from/bar.css')

        provider.find('path/to/foo.css')
        provider.find('path/from/bar.css')
      end

      it "works with double slashes in the path" do
        create_file('path/to/foo.css')
        provider.find('path/to//foo.css')
      end

      it "raises a Roadie::CSSFileNotFound error when the file could not be found" do
        expect {
          provider.find('not_here.css')
        }.to raise_error(Roadie::CSSFileNotFound, /not_here/)
      end
    end
  end
end
