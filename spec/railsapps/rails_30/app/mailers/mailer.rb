class Mailer < ActionMailer::Base
  default css: 'email'

  def normal_email
    mail(to: 'example@example.org') do |format|
      format.html
      format.text
    end
  end

  def extra_email
    mail(to: 'example@example.org') do |format|
      format.html
    end
  end
end
