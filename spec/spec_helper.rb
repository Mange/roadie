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
require 'roadie'

FIXTURES_PATH = Pathname.new(File.dirname(__FILE__)).join('fixtures')
Roadie::Railtie.run_initializers

class TestApplication
  def config
    @config ||= OpenStruct.new({
      :action_mailer => OpenStruct.new(:default_url_options => {:host => "example.com"}),
      :assets => OpenStruct.new(:enabled => false),
      :roadie => OpenStruct.new(:provider => nil),
    })
  end

  def assets
    env = Sprockets::Environment.new
    env.append_path root.join('app','assets','stylesheets')
    env
  end

  def root
    FIXTURES_PATH
  end
end

RSpec.configure do |c|
  c.before(:each) do
    Rails.stub(:application => TestApplication.new)
  end
end

Dir['./spec/support/**/*'].each { |file| require file }
