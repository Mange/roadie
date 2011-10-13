$: << File.dirname(__FILE__) + '/../lib'

require 'ostruct'
require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rspec'

require 'action_mailer'
require 'sprockets'
require 'roadie'

FIXTURES_PATH = Pathname.new(File.dirname(__FILE__)).join('fixtures')

class TestApplication
  def config
    OpenStruct.new(:action_mailer => OpenStruct.new(:default_url_options => {:host => "example.com"}))
  end

  def assets
    env = Sprockets::Environment.new
    env.append_path FIXTURES_PATH.join('app','assets','stylesheets')
    env
  end
end

unless defined?(Rails)
  class Rails; end
end

RSpec.configure do |c|
  c.before(:each) do
    Rails.stub(:application => TestApplication.new)
  end
end

Dir['./spec/support/**/*'].each { |file| require file }
