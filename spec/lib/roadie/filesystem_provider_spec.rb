# encoding: UTF-8
require 'spec_helper'
require 'roadie/rspec'
require 'shared_examples/asset_provider'

module Roadie
  describe FilesystemProvider do
    let(:fixtures_path) { File.expand_path "../../../fixtures", __FILE__ }
    subject(:provider) { FilesystemProvider.new(fixtures_path) }

    it_behaves_like "roadie asset provider", valid_name: "stylesheets/green.css", invalid_name: "foo"

    it "takes a path" do
      FilesystemProvider.new("/tmp").path.should == "/tmp"
    end

    it "defaults to the current working directory" do
      FilesystemProvider.new.path.should == Dir.pwd
    end

    describe "finding stylesheets" do
      it "finds files in the path" do
        full_path = File.join(fixtures_path, "stylesheets", "green.css")
        file_contents = File.read full_path

        stylesheet = provider.find_stylesheet("stylesheets/green.css")
        stylesheet.name.should == full_path
        stylesheet.to_s.should == Stylesheet.new("", file_contents).to_s
      end

      it "returns nil on non-existant files" do
        provider.find_stylesheet("non/existant.css").should be_nil
      end

      it "finds files inside the base path when using absolute paths" do
        full_path = File.join(fixtures_path, "stylesheets", "green.css")
        provider.find_stylesheet("/stylesheets/green.css").name.should == full_path
      end

      it "does not read files above the base directory" do
        expect {
          provider.find_stylesheet("../#{File.basename(__FILE__)}")
        }.to raise_error FilesystemProvider::InsecurePathError
      end
    end
  end
end
