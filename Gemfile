source 'https://rubygems.org'
gemspec

# Added here so it does not show up on the Gemspec; I only want it for CI builds
gem 'coveralls', group: :test, require: nil

group :guard do
  gem 'guard'
  gem 'guard-rspec'

  # Guard for Mac
  gem 'rb-fsevent', '>= 0.9.0.pre5'
  gem 'growl'
end
