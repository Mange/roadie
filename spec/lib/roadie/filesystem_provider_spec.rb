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
      expect(FilesystemProvider.new("/tmp").path).to eq("/tmp")
    end

    it "defaults to the current working directory" do
      expect(FilesystemProvider.new.path).to eq(Dir.pwd)
    end

    it "shows the given path in string representation" do
      expect(provider.to_s).to include provider.path.to_s
      expect(provider.inspect).to include provider.path.to_s
    end

    describe "finding stylesheets" do
      it "finds files in the path" do
        full_path = File.join(fixtures_path, "stylesheets", "green.css")
        file_contents = File.read full_path

        stylesheet = provider.find_stylesheet("stylesheets/green.css")
        expect(stylesheet).not_to be_nil
        expect(stylesheet.name).to eq(full_path)
        expect(stylesheet.to_s).to eq(Stylesheet.new("", file_contents).to_s)
      end

      it "returns nil on non-existant files" do
        expect(provider.find_stylesheet("non/existant.css")).to be_nil
      end

      it "finds files inside the base path when using absolute paths" do
        full_path = File.join(fixtures_path, "stylesheets", "green.css")
        expect(provider.find_stylesheet("/stylesheets/green.css").name).to eq(full_path)
      end

      it "does not read files above the base directory" do
        expect {
          provider.find_stylesheet("../#{File.basename(__FILE__)}")
        }.to raise_error FilesystemProvider::InsecurePathError
      end
    end

    describe "finding stylesheets with query strings" do
      it "ignores the query string" do
        full_path = File.join(fixtures_path, "stylesheets", "green.css")
        file_contents = File.read full_path

        stylesheet = provider.find_stylesheet("/stylesheets/green.css?time=111")
        expect(stylesheet).not_to be_nil
        expect(stylesheet.name).to eq(full_path)
        expect(stylesheet.to_s).to eq(Stylesheet.new("", file_contents).to_s)
      end

      it "shows that the query string is ignored inside raised errors" do
        begin
          provider.find_stylesheet!("/foo.css?query-string")
          fail "No error was raised"
        rescue CssNotFound => error
          expect(error.css_name).to eq("foo.css")
          expect(error.to_s).to include("/foo.css?query-string")
        end
      end
    end
  end
end
