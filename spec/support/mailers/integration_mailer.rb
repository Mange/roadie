class IntegrationMailer < ActionMailer::Base
  default :css => :integration, :from => 'john@example.com'
  append_view_path FIXTURES_PATH.join('views')

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

