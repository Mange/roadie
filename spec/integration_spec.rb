require 'spec_helper'

describe "roadie integration" do
  class TestApplication
    def config
      OpenStruct.new(:action_mailer => OpenStruct.new(:default_url_options => {:host => "example.app.org"}))
    end
  end

  class IntegrationMailer < ActionMailer::Base
    default :css => :integration, :from => 'john@example.com'
    append_view_path Pathname.new(__FILE__).dirname.join('fixtures').join('views')

    def notification(to, reason)
      @reason = reason
      mail(:subject => 'Notification for you', :to => to) { |format| format.html; format.text }
    end

    def marketing(to)
      headers('X-Spam' => 'No way! Trust us!')
      mail(:subject => 'Buy cheap v1agra', :to => to)
    end
  end

  before(:each) do
    Rails.stub!(:root => Pathname.new(__FILE__).dirname.join('fixtures'), :application => TestApplication.new)
    IntegrationMailer.delivery_method = :test
  end

  it "inlines styles for an email" do
    email = IntegrationMailer.notification('doe@example.com', 'your quota limit has been reached')

    email.to.should == ['doe@example.com']
    email.from.should == ['john@example.com']
    email.should have(2).parts

    email.parts.find { |part| part.mime_type == 'text/html' }.tap do |html_part|
      document = Nokogiri::HTML.parse(html_part.body.decoded)
      document.should have_selector('html > head + body')
      document.should have_selector('body #message h1')
      document.should have_styling('background' => 'url(http://example.app.org/images/dots.png) repeat-x').at_selector('body')
      document.should have_selector('strong[contains("quota")]')
    end

    email.parts.find { |part| part.mime_type == 'text/plain' }.tap do |plain_part|
      plain_part.body.decoded.should_not match(/<.*>/)
    end

    # If we deliver mails we can catch weird problems with headers being invalid
    email.deliver
  end

  it "does not add headers for the roadie options" do
    email = IntegrationMailer.notification('doe@example.com', 'no berries left in chest')
    email.header.fields.map(&:name).should_not include('css')
  end

  it "keeps custom headers in place" do
    email = IntegrationMailer.marketing('everyone@inter.net')
    email.header['X-Spam'].should be_present
  end
end
