$: << File.dirname(__FILE__) + '/../lib'
 
require 'rubygems'
require 'spec'
require 'action_mailer'
require 'mail_style'

# Extract HTML Part
def html_part(email)
  email.parts.select{|part| part.content_type == 'text/html'}.first.body
end

def css_rules(css)
  @css_rules = css
  
  # Stubs
  File.stub(:exist?).and_return(true)
  File.stub(:read).and_return(@css_rules)
end

# Debugging helper
module Kernel
  if ENV.keys.find {|env_var| env_var.match(/^TM_/)}
    def rputs(*args)
      puts( *["<pre>", args.collect {|a| CGI.escapeHTML(a.to_s)}, "</pre>"])
    end
  else
    alias_method :rputs, :puts
  end
end