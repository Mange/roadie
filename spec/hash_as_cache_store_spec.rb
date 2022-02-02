# frozen_string_literal: true

require "spec_helper"
require "roadie/rspec"

describe "Using Hash as a cache store" do
  subject(:hash) { {} }
  it_behaves_like "roadie cache store"
end
