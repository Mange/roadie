# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe UrlGenerator do
    it "is initialized with URL options" do
      UrlGenerator.new(host: "foo.com").url_options.should == {host: "foo.com"}
    end

    it "raises an argument error if no host is specified" do
      expect {
        UrlGenerator.new(port: 3000)
      }.to raise_error ArgumentError, /host/i
    end

    it "raises an argument error if unknown option is passed" do
      expect {
        UrlGenerator.new(host: "localhost", secret: true)
      }.to raise_error ArgumentError, /secret/
    end

    describe "generating URLs" do
      def url(path, options = {})
        UrlGenerator.new(options).generate_url(path)
      end

      it "uses the given host" do
        url("/hello.jpg", host: "goats.com").should == "http://goats.com/hello.jpg"
      end

      it "uses the given port" do
        url("/", host: "example.com", port: 1337).should == "http://example.com:1337/"
      end

      it "uses the given scheme" do
        url("/", host: "example.com", scheme: "https").should == "https://example.com/"
      end

      it "regards :protocol as an alias for scheme" do
        url("/", host: "example.com", protocol: "https").should == "https://example.com/"
      end

      it "strips extra characters from the scheme" do
        url("/", host: "example.com", scheme: "https://").should == "https://example.com/"
      end

      it "uses the given path as a prefix" do
        url("/my_file", host: "example.com", path: "/my_app").should ==
          "http://example.com/my_app/my_file"
      end

      it "returns the original URL if it is absolute" do
        url("http://foo.com/", host: "bar.com").should == "http://foo.com/"
      end

      it "returns the base URL for blank paths" do
        url("", host: "foo.com").should == "http://foo.com"
        url(nil, host: "foo.com").should == "http://foo.com"
      end

      it "raises an error on invalid path" do
        expect {
          url("://", host: "example.com")
        }.to raise_error InvalidUrlPath, %r{://}
      end

      it "accepts base paths without a slash in the beginning" do
        url("/bar", host: "example.com", path: "foo").should == "http://example.com/foo/bar"
        url("/bar/", host: "example.com", path: "foo/").should == "http://example.com/foo/bar/"
      end

      it "accepts input paths without a slash in the beginning" do
        url("bar", host: "example.com", path: "/foo").should == "http://example.com/foo/bar"
        url("bar", host: "example.com", path: "/foo/").should == "http://example.com/foo/bar"
      end
    end
  end
end
