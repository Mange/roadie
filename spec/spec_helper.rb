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
        TestMailer.stub!(:css_rules).with(Array(names)).and_return(rules)
      end
    end
  end
end

RSpec.configure do |config|
  config.extend SpecHelpers::StylingMacros
end