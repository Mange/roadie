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

if defined?(Rails)
  Rails.stub!(:root => Pathname.new('/path/to'))
else
  class Rails
    def self.root; Pathname.new('/path/to'); end
  end
end

ActionMailer::Base.configure do |config|
  config.perform_deliveries = false
  config.default_url_options = {:host => "example.com"}
end

RSpec::Matchers.define :have_styling do |rules|
  chain :at_selector do |selector|
    @selector = selector
  end

  match do |document|
    styles = parsed_styles(document)
    if rules.nil?
      styles.blank?
    else
      rules.stringify_keys.should == parsed_styles(document)
    end
  end

  describe { "have styles #{rules.inspect} at selector #{@selector.inspect}" }
  failure_message_for_should { |document| "expected styles at #{@selector.inspect} to be #{rules.inspect} but was #{parsed_styles(document).inspect}" }
  failure_message_for_should_not { "expected styles at #{@selector.inspect} to not be #{rules.inspect}" }

  def element_styles(document)
    node = document.css(@selector).first
    node && node['style']
  end

  def parsed_styles(document)
    return @parsed_styles if defined?(@parsed_styles)
    if (styles = element_styles(document)).present?
      @parsed_styles = styles.split(';').inject({}) do |styles, item|
        attribute, value = item.split(':', 2)
        styles.merge!(attribute.strip => value.strip)
      end
    else
      @parsed_styles = nil
    end
  end
end

RSpec::Matchers.define :have_attribute do |attribute|
  chain :at_selector do |selector|
    @selector = selector
  end

  match do |document|
    name, expected = attribute.first
    expected == attribute(document, name)
  end

  describe { "have attribute #{attribute.inspect} at selector #{@selector.inspect}" }
  failure_message_for_should do |document|
    name, expected = attribute.first
    "expected #{name} attribute at #{@selector.inspect} to be #{expected.inspect} but was #{attribute(document, name).inspect}"
  end
  failure_message_for_should_not do |document|
    name, expected = attribute.first
    "expected #{name} attribute at #{@selector.inspect} to not be #{expected.inspect}"
  end

  def attribute(document, attribute_name)
    node = document.css(@selector).first
    node && node[attribute_name]
  end
end

RSpec::Matchers.define :have_selector do |selector|
  match { |document| document.css(selector).present? }
  failure_message_for_should { "expected document to #{name_to_sentence}#{expected_to_sentence}"}
  failure_message_for_should_not { "expected document to not #{name_to_sentence}#{expected_to_sentence}"}
end

