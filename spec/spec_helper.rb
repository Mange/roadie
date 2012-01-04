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
require 'rails'
require 'sprockets'

require 'roadie/railtie'
require 'action_mailer/railtie'

FIXTURES_PATH = Pathname.new(File.dirname(__FILE__)).join('fixtures')

class TestApplication < Rails::Application
  def config
    @config
  end

  def assets
    env = Sprockets::Environment.new
    env.append_path root.join('app','assets','stylesheets')
    env
  end

  def root
    FIXTURES_PATH
  end

  def reset_test_config
    @config = OpenStruct.new({
      :action_mailer => OpenStruct.new(:default_url_options => {}),
      :assets => OpenStruct.new(:enabled => false),
      :roadie => OpenStruct.new(:provider => nil),
    })
    change_default_url_options(:host => "example.com")
  end
end

if Roadie::Railtie.respond_to?(:run_initializers)
  # Rails >= 3.1
  ActionMailer::Railtie.run_initializers(:default, Rails.application)
  Roadie::Railtie.run_initializers(:default, Rails.application)
else
  # Rails 3.0
  Rails.application.config.active_support.deprecation = :log
  Rails.logger = Logger.new('/dev/null')
  Rails.application.initialize!
end

RSpec.configure do |c|
  c.before(:each) do
    Rails.application.reset_test_config
  end
end

Dir['./spec/support/**/*.rb'].each { |file| require file }
