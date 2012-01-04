require 'spec_helper'

module Roadie
  shared_examples "roadie integration" do
    mailer = Class.new(AnonymousMailer) do
      default :css => :integration, :from => 'john@example.com'
      append_view_path FIXTURES_PATH.join('views')

      # Needed for correct path lookup
      self.mailer_name = "integration_mailer"

      def notification(to, reason)
        @reason = reason
        mail(:subject => 'Notification for you', :to => to) { |format| format.html; format.text }
      end

      def marketing(to)
        headers('X-Spam' => 'No way! Trust us!')
        mail(:subject => 'Buy cheap v1agra', :to => to)
      end

      def url_options
        # This allows apps to calculate any options on a per-email basis
        super.merge(:protocol => 'https')
      end
    end

    before(:each) do
      change_default_url_options(:host => 'example.app.org')
      mailer.delivery_method = :test
    end

    it "inlines styles for an email" do
      email = mailer.notification('doe@example.com', 'your quota limit has been reached')

      email.to.should == ['doe@example.com']
      email.from.should == ['john@example.com']
      email.should have(2).parts

      email.parts.find { |part| part.mime_type == 'text/html' }.tap do |html_part|
        document = Nokogiri::HTML.parse(html_part.body.decoded)
        document.should have_selector('html > head + body')
        document.should have_selector('body #message h1')
        document.should have_styling('background' => 'url(https://example.app.org/images/dots.png) repeat-x').at_selector('body')
        document.should have_selector('strong[contains("quota")]')
      end

      email.parts.find { |part| part.mime_type == 'text/plain' }.tap do |plain_part|
        plain_part.body.decoded.should_not match(/<.*>/)
      end

      # If we deliver mails we can catch weird problems with headers being invalid
      email.deliver
    end

    it "does not add headers for the roadie options" do
      email = mailer.notification('doe@example.com', 'no berries left in chest')
      email.header.fields.map(&:name).should_not include('css')
    end

    it "keeps custom headers in place" do
      email = mailer.marketing('everyone@inter.net')
      email.header['X-Spam'].should be_present
    end

    it "applies CSS3 styles" do
      email = mailer.notification('doe@example.com', 'your quota limit has been reached')
      document = Nokogiri::HTML.parse(email.html_part.body.decoded)
      strong_node = document.css('strong').first
      stylings = SpecHelpers.styling_of_node(strong_node)
      stylings.should include(['box-shadow', '#62b0d7 1px 1px 1px 1px inset, #aaaaaa 1px 1px 3px 0'])
      stylings.should include(['-o-box-shadow', '#62b0d7 1px 1px 1px 1px inset, #aaaaaa 1px 1px 3px 0'])
    end
  end

  describe "filesystem integration" do
    it_behaves_like "roadie integration" do
      before(:each) { Rails.application.config.assets.enabled = false }
    end
  end

  describe "asset pipeline integration" do
    it_behaves_like "roadie integration" do
      before(:each) { Rails.application.config.assets.enabled = true }
    end
  end
end
