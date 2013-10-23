require 'coveralls'
Coveralls.wear!

$: << File.dirname(__FILE__) + '/../lib'
require 'roadie'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
end

Dir['./spec/support/**/*.rb'].each { |file| require file }
