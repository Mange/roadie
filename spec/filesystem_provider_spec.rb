# encoding: UTF-8
require 'spec_helper'
require 'shared_examples/asset_provider'

module Roadie
  describe FilesystemProvider do
    it_behaves_like "asset provider"
    it_behaves_like "delegating find_stylesheet! method"

    it "takes a path" do
      FilesystemProvider.new("/tmp").path.should == "/tmp"
    end

    it "defaults to the current working directory" do
      FilesystemProvider.new.path.should == Dir.pwd
    end

    describe "finding stylesheets" do
      let(:fixtures_path) { File.expand_path "../fixtures", __FILE__ }
      let(:provider) { FilesystemProvider.new(fixtures_path) }

      it "finds files in the path" do
        green_css = File.read File.join(fixtures_path, "stylesheets", "green.css")
        provider.find_stylesheet("stylesheets/green.css").should == green_css
      end

      it "returns nil on non-existant files" do
        provider.find_stylesheet("non/existant.css").should be_nil
      end

      it "finds files inside the base path when using absolute paths" do
        green_css = File.read File.join(fixtures_path, "stylesheets", "green.css")
        provider.find_stylesheet("/stylesheets/green.css").should == green_css
      end

      it "does not read files above the base directory" do
        expect {
          provider.find_stylesheet("../#{File.basename(__FILE__)}")
        }.to raise_error FilesystemProvider::InsecurePathError
      end
    end
  end
end
