require 'rspec/collection_matchers'
require 'webmock/rspec'

if ENV['CI']
  require 'coveralls'
  Coveralls.wear!
end

$: << File.dirname(__FILE__) + '/../lib'
require 'roadie'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
end

Dir['./spec/support/**/*.rb'].each { |file| require file }
