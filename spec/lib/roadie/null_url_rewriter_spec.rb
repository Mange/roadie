# encoding: UTF-8
require 'spec_helper'
require 'shared_examples/url_rewriter'

module Roadie
  describe NullUrlRewriter do
    let(:generator) { double "URL generator" }
    subject(:rewriter) { NullUrlRewriter.new(generator) }

    it_behaves_like "url rewriter"

    it "does nothing when transforming DOM" do
      dom = double "DOM tree"
      expect {
        NullUrlRewriter.new(generator).transform_dom dom
      }.to_not raise_error
    end
  end
end
