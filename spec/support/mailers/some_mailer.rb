class SomeMailer < ActionMailer::Base
  default :css => :default

  def default_css
    mail(:subject => "Default CSS") do |format|
      format.html { render :text => '' }
    end
  end

  def override_css(css)
    mail(:subject => "Default CSS", :css => css) do |format|
      format.html { render :text => '' }
    end
  end

  def multipart
    mail(:subject => "Multipart email") do |format|
      format.html { render :text => 'Hello HTML' }
      format.text { render :text => 'Hello Text' }
    end
  end

  def singlepart_html
    mail(:subject => "HTML email") do |format|
      format.html { render :text => 'Hello HTML' }
    end
  end

  def singlepart_plain
    mail(:subject => "Text email") do |format|
      format.text { render :text => 'Hello Text' }
    end
  end
end
