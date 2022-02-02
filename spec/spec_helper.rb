# frozen_string_literal: true

require "rspec/collection_matchers"
require "webmock/rspec"

if ENV["CI"]
  require "simplecov"
  SimpleCov.start

  require "codecov"
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

$: << File.dirname(__FILE__) + "/../lib"
require "roadie"

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
end

Dir["./spec/support/**/*.rb"].sort.each { |file| require file }
