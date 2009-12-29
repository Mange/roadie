# coding: utf-8
$: << File.dirname(__FILE__) + '/../lib'
 
require 'rubygems'
require 'spec'
require 'actionmailer'
require 'shemail'

# Extract HTML Part
def html_part(email)
  email.parts.select{|part| part.content_type == 'text/html'}.first.body.to_s
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