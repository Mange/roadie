class SimpleMailer < ActionMailer::Base
  default :css => :simple

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
