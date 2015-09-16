require 'spec_helper'
require 'roadie/rspec'
require 'shared_examples/asset_provider'

module Roadie
  describe NetHttpProvider do
    around do |example|
      WebMock.disable_net_connect!
      example.run
      WebMock.allow_net_connect!
    end

    url = "http://example.com/style.css".freeze

    it_behaves_like(
      "roadie asset provider",
      valid_name: "http://example.com/green.css",
      invalid_name: "http://example.com/red.css"
    ) do
      before do
        stub_request(:get, "http://example.com/green.css").and_return(body: "p { color: green; }")
        stub_request(:get, "http://example.com/red.css").and_return(status: 404, body: "Not here!")
      end
    end

    it "can download over HTTPS" do
      stub_request(:get, "https://example.com/style.css").and_return(body: "p { color: green; }")
      expect {
        NetHttpProvider.new.find_stylesheet!("https://example.com/style.css")
      }.to_not raise_error
    end

    it "assumes HTTPS when given a scheme-less URL" do
      # Some people might re-use the same template as they use on a webpage,
      # and browsers support URLs without a scheme in them, replacing the
      # scheme with the current one. There's no "current" scheme when doing
      # asset inlining, but the scheme-less URL implies that there should exist
      # both a HTTP and a HTTPS endpoint. Let's take the secure one in that
      # case!
      stub_request(:get, "https://example.com/style.css").and_return(body: "p { color: green; }")
      expect {
        NetHttpProvider.new.find_stylesheet!("//example.com/style.css")
      }.to_not raise_error
    end

    describe "error handling" do
      it "handles timeouts" do
        stub_request(:get, url).and_timeout
        expect {
          NetHttpProvider.new.find_stylesheet!(url)
        }.to raise_error CssNotFound, /timeout/i

        expect { NetHttpProvider.new.find_stylesheet(url) }.to_not raise_error
      end

      it "displays response code and beginning of message body" do
        stub_request(:get, url).and_return(
          status: 503,
          body: "Whoah there! Didn't you see we have a service window at this
                time? It's kind of disrespectful not to remember everything I tell
                you all the time!"
        )

        expect {
          NetHttpProvider.new.find_stylesheet!(url)
        }.to raise_error CssNotFound, /503.*whoah/i
      end
    end

    describe "whitelist" do
      it "can have a whitelist of host names" do
        provider = NetHttpProvider.new(whitelist: ["example.com", "foo.bar"])
        expect(provider.whitelist).to eq Set["example.com", "foo.bar"]
      end

      it "defaults to empty whitelist" do
        expect(NetHttpProvider.new.whitelist).to eq Set[]
        expect(NetHttpProvider.new(whitelist: nil).whitelist).to eq Set[]
      end

      it "will not download from other hosts if set" do
        provider = NetHttpProvider.new(whitelist: ["whitelisted.example.com"])

        whitelisted_url = "http://whitelisted.example.com/style.css"
        other_url       = "http://www.example.com/style.css"

        whitelisted_request = stub_request(:get, whitelisted_url).and_return(body: "x")
        other_request       = stub_request(:get, other_url).and_return(body: "x")

        expect(provider.find_stylesheet(other_url)).to be_nil
        expect {
          provider.find_stylesheet!(other_url)
        }.to raise_error CssNotFound, /whitelist/

        expect {
          expect(provider.find_stylesheet(whitelisted_url)).to_not be_nil
          provider.find_stylesheet!(whitelisted_url)
        }.to_not raise_error

        expect(whitelisted_request).to have_been_made.twice
        expect(other_request).to_not have_been_made
      end

      it "is displayed in the string representation" do
        expect(NetHttpProvider.new(whitelist: ["bar.baz"]).to_s).to include "bar.baz"
      end

      it "raises error when given invalid hostnames" do
        expect { NetHttpProvider.new(whitelist: [nil]) }.to raise_error(ArgumentError)
        expect { NetHttpProvider.new(whitelist: [""]) }.to raise_error(ArgumentError)
        expect { NetHttpProvider.new(whitelist: ["."]) }.to raise_error(ArgumentError)
        expect { NetHttpProvider.new(whitelist: ["http://foo.bar"]) }.to raise_error(ArgumentError)
        expect { NetHttpProvider.new(whitelist: ["foo/bar"]) }.to raise_error(ArgumentError)
      end
    end
  end
end
