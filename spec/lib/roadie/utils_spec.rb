require "spec_helper"

module Roadie
  describe Utils, "path_is_absolute?" do
    RSpec::Matchers.define :be_absolute do
      match { |path| Utils.path_is_absolute?(path) }
    end

    it "detects absolute HTTP URLs" do
      expect("http://example.com").to be_absolute
      expect("https://example.com").to be_absolute
      expect("https://example.com/path?foo=bar").to be_absolute
    end

    it "detects absolute URLs without schemes" do
      expect("//example.com").to be_absolute
      expect("//").to be_absolute
    end

    it "detects relative URLs without hosts" do
      expect("path/to/me").not_to be_absolute
      expect("/path/to/me").not_to be_absolute
      expect("../../path").not_to be_absolute
      expect("/").not_to be_absolute
    end
  end

  describe Utils, "warn" do
    it "passes the message on to Kernel.warn" do
      expect(Kernel).to receive(:warn).with("Roadie: Hello from specs")
      Utils.warn "Hello from specs"
    end
  end
end
