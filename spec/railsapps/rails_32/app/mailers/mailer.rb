class Mailer < ActionMailer::Base
  default css: 'email', from: 'john@example.com'

  def normal_email
    mail(to: 'example@example.org', subject: "Notification for you") do |format|
      format.html
      format.text
    end
  end

  def extra_email
    headers('X-Spam' => 'No way! Trust us!')
    mail(to: 'example@example.org') do |format|
      format.html
    end
  end

  def url_options
    # This allows apps to calculate any options on a per-email basis
    super.merge(:protocol => 'https')
  end
end
