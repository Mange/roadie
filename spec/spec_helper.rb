$: << File.dirname(__FILE__) + '/../lib'

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
require 'mail_style'

module SpecHelpers
  module StylingMacros
    def use_css(names, rules)
      before(:each) do
        MailStyle.stub!(:load_css).with(anything, Array(names)).and_return(rules)
      end
    end
  end
end

if defined?(Rails)
  Rails.stub!(:root => Pathname.new('/path/to'))
else
  class Rails
    def self.root; Pathname.new('/path/to'); end
  end
end

RSpec.configure do |config|
  config.extend SpecHelpers::StylingMacros
end

