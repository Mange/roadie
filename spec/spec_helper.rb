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

Dir['./spec/support/**/*'].each { |file| require file }

require 'action_mailer'
require 'roadie'

class TestApplication
  def config
    OpenStruct.new(:action_mailer => OpenStruct.new(:default_url_options => {:host => "example.com"}))
  end
end

if defined?(Rails)
  Rails.stub!(:root => Pathname.new('/path/to'), :application => TestApplication.new)
else
  class Rails
    def self.root; Pathname.new('/path/to'); end
    def self.application; TestApplication.new; end
  end
end

