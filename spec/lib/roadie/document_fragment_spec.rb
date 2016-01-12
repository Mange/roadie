# encoding: UTF-8
require 'spec_helper'

module Roadie
  describe DocumentFragment do
    sample_html = "<div><p>Hello world!</p></div>"
    subject(:fragment) { described_class.new sample_html }

    it "is initialized with HTML" do
      doc = DocumentFragment.new "<div></div>"
      expect(doc.html).to eq("<div></div>")
    end

    it "has an accessor for URL options" do
      fragment.url_options = {host: "foo.bar"}
      expect(fragment.url_options).to eq({host: "foo.bar"})
    end

    it "has a setting for keeping uninlinable styles" do
      expect(fragment.keep_uninlinable_css).to be true
      fragment.keep_uninlinable_css = false
      expect(fragment.keep_uninlinable_css).to be false
    end

    it "has a ProviderList for normal and external providers" do
      expect(fragment.asset_providers).to be_instance_of(ProviderList)
      expect(fragment.external_asset_providers).to be_instance_of(ProviderList)
    end

    it "defaults to having just a FilesystemProvider in the normal provider list" do
      expect(fragment).to have(1).asset_providers
      expect(fragment).to have(0).external_asset_providers

      provider = fragment.asset_providers.first
      expect(provider).to be_instance_of(FilesystemProvider)
    end

    it "allows changes to the normal asset providers" do
      other_provider = double "Other proider"
      old_list = fragment.asset_providers

      fragment.asset_providers = [other_provider]
      expect(fragment.asset_providers).to be_instance_of(ProviderList)
      expect(fragment.asset_providers.each.to_a).to eq([other_provider])

      fragment.asset_providers = old_list
      expect(fragment.asset_providers).to eq(old_list)
    end

    it "allows changes to the external asset providers" do
      other_provider = double "Other proider"
      old_list = fragment.external_asset_providers

      fragment.external_asset_providers = [other_provider]
      expect(fragment.external_asset_providers).to be_instance_of(ProviderList)
      expect(fragment.external_asset_providers.each.to_a).to eq([other_provider])

      fragment.external_asset_providers = old_list
      expect(fragment.external_asset_providers).to eq(old_list)
    end

    it "can store callbacks for inlining" do
      callable = double "Callable"

      fragment.before_transformation = callable
      fragment.after_transformation = callable

      expect(fragment.before_transformation).to eq(callable)
      expect(fragment.after_transformation).to eq(callable)
    end

    describe "transforming" do
      it "runs the before and after callbacks" do
        fragment = DocumentFragment.new "<div></div>"
        before = ->{}
        after = ->{}
        fragment.before_transformation = before
        fragment.after_transformation = after

        expect(before).to receive(:call).with(instance_of(Nokogiri::HTML::DocumentFragment), fragment).ordered
        expect(Inliner).to receive(:new).ordered.and_return double.as_null_object
        expect(after).to receive(:call).with(instance_of(Nokogiri::HTML::DocumentFragment), fragment).ordered

        fragment.transform
      end

      # TODO: Remove on next major version.
      it "works on callables that don't expect more than one argument" do
        fragment = DocumentFragment.new "<div></div>"
        fragment.before_transformation = ->(first) { }
        fragment.after_transformation = ->(first = nil) { }

        expect { fragment.transform }.to_not raise_error

        # It still supplies the second argument, if possible.
        fragment.after_transformation = ->(first, second = nil) {
          raise "Oops" unless second
        }
        expect { fragment.transform }.to_not raise_error
      end
    end
  end

  describe DocumentFragment, "(integration)" do
    it "can transform the fragment" do
      fragment = DocumentFragment.new("<p>Hello, world!</p>")

      fragment.add_css "p { color: green; }"

      result = fragment.transform

      expect(result).to eq('<p style="color:green">Hello, world!</p>')
    end

    it "extracts styles from the HTML" do
      fragment = DocumentFragment.new <<-HTML
        <link rel="stylesheet" href="/sample.css" type="text/css">
        <p>Hello, world!</p>
      HTML

      fragment.asset_providers = TestProvider.new({
        "/sample.css" => "p { color: red; text-align: right; }",
      })

      fragment.add_css "p { color: green; text-size: 2em; }"

      result = Nokogiri::HTML::DocumentFragment.parse fragment.transform

      expect(result).to have_styling([
        %w[color red],
        %w[text-align right],
        %w[color green],
        %w[text-size 2em]
      ]).at_selector("p")
    end
  end
end
